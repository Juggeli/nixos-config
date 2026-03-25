#!/usr/bin/env python3

import argparse
import json
import logging
import os
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional
import requests

REQUEST_TIMEOUT = 30


@dataclass
class SeriesInfo:
    id: int
    title: str
    path: str
    size_on_disk: int
    monitored: bool
    status: str
    added: Optional[datetime]


@dataclass
class WatchStatus:
    all_watched: bool
    last_watched: Optional[datetime]
    total_episodes: int
    watched_episodes: int


class SonarrClient:
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip("/")
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers["X-Api-Key"] = api_key
        self.logger = logging.getLogger("sonarr")

    def get_series(self) -> list[SeriesInfo]:
        resp = self.session.get(f"{self.url}/api/v3/series", timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        series_list = []
        for s in resp.json():
            added = None
            if s.get("added"):
                added = datetime.fromisoformat(s["added"].replace("Z", "+00:00")).replace(tzinfo=None)
            series_list.append(SeriesInfo(
                id=s["id"],
                title=s["title"],
                path=s["path"],
                size_on_disk=s.get("statistics", {}).get("sizeOnDisk", 0),
                monitored=s["monitored"],
                status=s.get("status", "unknown"),
                added=added,
            ))
        return series_list

    def get_episodes(self, series_id: int) -> list[dict]:
        resp = self.session.get(f"{self.url}/api/v3/episode", params={"seriesId": series_id}, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        return resp.json()

    def get_episodes_with_files(self, series_id: int) -> list[dict]:
        episodes = self.get_episodes(series_id)
        return [ep for ep in episodes if ep.get("hasFile", False)]

    def get_episode_files(self, series_id: int) -> list[dict]:
        resp = self.session.get(f"{self.url}/api/v3/episodefile", params={"seriesId": series_id}, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        return resp.json()

    def delete_episode_files(self, file_ids: list[int]) -> None:
        for file_id in file_ids:
            resp = self.session.delete(f"{self.url}/api/v3/episodefile/{file_id}", timeout=REQUEST_TIMEOUT)
            resp.raise_for_status()

    def unmonitor_series(self, series_id: int) -> None:
        resp = self.session.get(f"{self.url}/api/v3/series/{series_id}", timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        series_data = resp.json()
        series_data["monitored"] = False
        resp = self.session.put(f"{self.url}/api/v3/series/{series_id}", json=series_data, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()


class JellyfinClient:
    def __init__(self, url: str, api_key: str, username: str):
        self.url = url.rstrip("/")
        self.api_key = api_key
        self.username = username
        self.session = requests.Session()
        self.session.headers["X-Emby-Token"] = api_key
        self.logger = logging.getLogger("jellyfin")
        self._user_id: Optional[str] = None

    def _get_user_id(self) -> str:
        if self._user_id:
            return self._user_id
        resp = self.session.get(f"{self.url}/Users", timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        for user in resp.json():
            if user["Name"].lower() == self.username.lower():
                self._user_id = user["Id"]
                return self._user_id
        raise ValueError(f"Jellyfin user '{self.username}' not found")

    def _find_series_id(self, user_id: str, series_name: str) -> Optional[str]:
        resp = self.session.get(
            f"{self.url}/Users/{user_id}/Items",
            params={
                "IncludeItemTypes": "Series",
                "Recursive": True,
                "SearchTerm": series_name,
            },
            timeout=REQUEST_TIMEOUT,
        )
        resp.raise_for_status()
        items = resp.json().get("Items", [])
        for item in items:
            if item.get("Name", "").lower() == series_name.lower():
                return item.get("Id")
        return None

    def get_watch_status(self, series_name: str, sonarr_episodes: list[dict]) -> Optional[WatchStatus]:
        try:
            user_id = self._get_user_id()
            series_id = self._find_series_id(user_id, series_name)
            if not series_id:
                self.logger.debug(f"Series '{series_name}' not found in Jellyfin")
                return None

            resp = self.session.get(
                f"{self.url}/Users/{user_id}/Items",
                params={
                    "ParentId": series_id,
                    "IncludeItemTypes": "Episode",
                    "Recursive": True,
                    "Fields": "UserData",
                },
                timeout=REQUEST_TIMEOUT,
            )
            resp.raise_for_status()
            jf_episodes = resp.json().get("Items", [])

            jf_lookup: dict[tuple[int, int], dict] = {}
            for ep in jf_episodes:
                season = ep.get("ParentIndexNumber")
                episode = ep.get("IndexNumber")
                if season is not None and episode is not None:
                    jf_lookup[(season, episode)] = ep

            sonarr_keys = set()
            unmappable_count = 0
            for ep in sonarr_episodes:
                season = ep.get("seasonNumber")
                episode = ep.get("episodeNumber")
                if season is not None and episode is not None:
                    sonarr_keys.add((season, episode))
                else:
                    unmappable_count += 1

            total = len(sonarr_keys) + unmappable_count
            if total == 0:
                return WatchStatus(all_watched=False, last_watched=None, total_episodes=0, watched_episodes=0)

            watched = 0
            last_watched: Optional[datetime] = None

            for key in sonarr_keys:
                jf_ep = jf_lookup.get(key)
                if jf_ep:
                    user_data = jf_ep.get("UserData", {})
                    if user_data.get("Played", False):
                        watched += 1
                        last_played_str = user_data.get("LastPlayedDate")
                        if last_played_str:
                            last_played = datetime.fromisoformat(last_played_str.replace("Z", "+00:00")).replace(tzinfo=None)
                            if last_watched is None or last_played > last_watched:
                                last_watched = last_played

            self.logger.debug(
                f"'{series_name}': {watched}/{total} episodes with files watched, "
                f"last watched: {last_watched}"
            )
            return WatchStatus(
                all_watched=(watched == total),
                last_watched=last_watched,
                total_episodes=total,
                watched_episodes=watched,
            )
        except ValueError:
            raise
        except Exception as e:
            self.logger.warning(f"Error fetching Jellyfin data for '{series_name}': {e}")
            return None

    def get_any_user_last_watched(self, series_name: str) -> Optional[datetime]:
        try:
            resp = self.session.get(f"{self.url}/Users", timeout=REQUEST_TIMEOUT)
            resp.raise_for_status()
            users = resp.json()
        except Exception as e:
            self.logger.warning(f"Error fetching Jellyfin users: {e}")
            return None

        latest: Optional[datetime] = None

        for user in users:
            user_id = user["Id"]
            user_name = user["Name"]
            try:
                series_id = self._find_series_id(user_id, series_name)
                if not series_id:
                    continue

                resp = self.session.get(
                    f"{self.url}/Users/{user_id}/Items",
                    params={
                        "ParentId": series_id,
                        "IncludeItemTypes": "Episode",
                        "Recursive": True,
                        "Fields": "UserData",
                        "Filters": "IsPlayed",
                        "SortBy": "DatePlayed",
                        "SortOrder": "Descending",
                        "Limit": 1,
                    },
                    timeout=REQUEST_TIMEOUT,
                )
                resp.raise_for_status()
                episodes = resp.json().get("Items", [])

                if episodes:
                    last_played_str = episodes[0].get("UserData", {}).get("LastPlayedDate")
                    if last_played_str:
                        last_played = datetime.fromisoformat(last_played_str.replace("Z", "+00:00")).replace(tzinfo=None)
                        self.logger.debug(f"User '{user_name}' last watched '{series_name}' on {last_played}")
                        if latest is None or last_played > latest:
                            latest = last_played
            except Exception as e:
                self.logger.warning(f"Error checking watch history for user '{user_name}': {e}")

        return latest


class NtfyClient:
    def __init__(self, topic: str, server_url: str = "https://ntfy.sh"):
        self.topic = topic
        self.server_url = server_url.rstrip("/")
        self.logger = logging.getLogger("ntfy")

    def send(self, title: str, message: str, priority: str = "default", tags: Optional[list[str]] = None) -> None:
        try:
            headers = {"Title": title, "Priority": priority}
            if tags:
                headers["Tags"] = ",".join(tags)
            resp = requests.post(
                f"{self.server_url}/{self.topic}",
                data=message.encode("utf-8"),
                headers=headers,
                timeout=REQUEST_TIMEOUT,
            )
            resp.raise_for_status()
            self.logger.debug(f"Sent ntfy notification: {title}")
        except Exception as e:
            self.logger.warning(f"Failed to send ntfy notification: {e}")


@dataclass
class PendingDeletion:
    series_id: int
    series_title: str
    marked_date: str
    size_bytes: int


class StateManager:
    def __init__(self, state_file: Path):
        self.state_file = state_file
        self.pending: dict[int, PendingDeletion] = {}
        self.load()

    def load(self) -> None:
        if self.state_file.exists():
            with open(self.state_file) as f:
                data = json.load(f)
                for series_id_str, entry in data.get("pending", {}).items():
                    series_id = int(series_id_str)
                    self.pending[series_id] = PendingDeletion(
                        series_id=series_id,
                        series_title=entry["series_title"],
                        marked_date=entry["marked_date"],
                        size_bytes=entry.get("size_bytes", 0),
                    )

    def save(self) -> None:
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        data = {
            "pending": {
                str(p.series_id): {
                    "series_title": p.series_title,
                    "marked_date": p.marked_date,
                    "size_bytes": p.size_bytes,
                }
                for p in self.pending.values()
            }
        }
        with open(self.state_file, "w") as f:
            json.dump(data, f, indent=2)

    def mark_for_deletion(self, series: SeriesInfo) -> bool:
        if series.id in self.pending:
            return False
        self.pending[series.id] = PendingDeletion(
            series_id=series.id,
            series_title=series.title,
            marked_date=datetime.now().isoformat(),
            size_bytes=series.size_on_disk,
        )
        return True

    def is_past_grace_period(self, series_id: int, grace_days: int) -> bool:
        if series_id not in self.pending:
            return False
        marked_date = datetime.fromisoformat(self.pending[series_id].marked_date)
        return datetime.now() - marked_date >= timedelta(days=grace_days)

    def remove(self, series_id: int) -> None:
        self.pending.pop(series_id, None)


class CleanupManager:
    def __init__(
        self,
        sonarr: SonarrClient,
        jellyfin: JellyfinClient,
        state: StateManager,
        ntfy: Optional[NtfyClient],
        threshold_days: int,
        grace_days: int,
        dry_run: bool,
        whitelist: set[str],
    ):
        self.sonarr = sonarr
        self.jellyfin = jellyfin
        self.state = state
        self.ntfy = ntfy
        self.threshold_days = threshold_days
        self.grace_days = grace_days
        self.dry_run = dry_run
        self.whitelist = whitelist
        self.logger = logging.getLogger("cleanup")

    def delete_series_files(self, series: SeriesInfo) -> None:
        episode_files = self.sonarr.get_episode_files(series.id)
        file_ids = [f["id"] for f in episode_files]

        if file_ids:
            self.logger.info(f"Deleting {len(file_ids)} episode files for '{series.title}'")
            if not self.dry_run:
                self.sonarr.delete_episode_files(file_ids)

        self.logger.info(f"Unmonitoring series '{series.title}'")
        if not self.dry_run:
            self.sonarr.unmonitor_series(series.id)

    def format_size(self, size_bytes: int) -> str:
        for unit in ["B", "KB", "MB", "GB", "TB"]:
            if size_bytes < 1024:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024
        return f"{size_bytes:.2f} PB"

    def process_series(self, series: SeriesInfo) -> str:
        if series.size_on_disk == 0:
            return "skipped_no_files"

        if series.title.lower() in self.whitelist:
            if series.id in self.state.pending:
                self.logger.info(f"'{series.title}' is whitelisted, removing from deletion queue")
                self.state.remove(series.id)
            else:
                self.logger.debug(f"'{series.title}' is whitelisted, skipping")
            return "skipped_whitelisted"

        if series.status != "ended":
            self.logger.debug(f"'{series.title}' status is '{series.status}', skipping (not ended)")
            return "skipped_not_ended"

        sonarr_episodes = self.sonarr.get_episodes_with_files(series.id)
        if not sonarr_episodes:
            self.logger.debug(f"'{series.title}' has no episodes with files in Sonarr, skipping")
            return "skipped_no_files"

        watch_status = self.jellyfin.get_watch_status(series.title, sonarr_episodes)

        if watch_status is None:
            self.logger.debug(f"'{series.title}' not found in Jellyfin, skipping")
            return "skipped_not_found"

        if not watch_status.all_watched:
            self.logger.debug(
                f"'{series.title}' not fully watched "
                f"({watch_status.watched_episodes}/{watch_status.total_episodes}), skipping"
            )
            if series.id in self.state.pending:
                self.logger.info(f"  -> Removing from deletion queue (not fully watched)")
                self.state.remove(series.id)
                return "rescued"
            return "skipped_not_fully_watched"

        if watch_status.last_watched:
            days_ago = (datetime.now() - watch_status.last_watched).days
            if days_ago < self.threshold_days:
                self.logger.info(
                    f"'{series.title}' fully watched, last watched {days_ago} days ago (threshold: {self.threshold_days})"
                )
                if series.id in self.state.pending:
                    self.logger.info(f"  -> Removing from deletion queue (watched recently)")
                    self.state.remove(series.id)
                    return "rescued"
                return "watched_recently"
        else:
            self.logger.debug(f"'{series.title}' fully watched but no last watched date, skipping")
            return "skipped_no_watch_date"

        any_user_last = self.jellyfin.get_any_user_last_watched(series.title)
        if any_user_last:
            any_user_days_ago = (datetime.now() - any_user_last).days
            if any_user_days_ago < self.threshold_days:
                self.logger.info(
                    f"'{series.title}' watched by another user {any_user_days_ago} days ago, skipping"
                )
                if series.id in self.state.pending:
                    self.logger.info(f"  -> Removing from deletion queue (watched by another user)")
                    self.state.remove(series.id)
                    return "rescued"
                return "watched_by_others"

        days_since = f"{(datetime.now() - watch_status.last_watched).days} days ago"
        self.logger.debug(f"'{series.title}' fully watched, last watched: {days_since}")

        if series.id not in self.state.pending:
            self.state.mark_for_deletion(series)
            size_str = self.format_size(series.size_on_disk)
            self.logger.info(
                f"Marking '{series.title}' for deletion ({size_str}, "
                f"{watch_status.watched_episodes}/{watch_status.total_episodes} watched, "
                f"last watched: {days_since})"
            )
            if self.ntfy and not self.dry_run:
                self.ntfy.send(
                    title="Anime Marked for Cleanup",
                    message=(
                        f"'{series.title}' ({size_str}) will be deleted in {self.grace_days} days.\n"
                        f"All {watch_status.total_episodes} episodes watched, last watched: {days_since}"
                    ),
                    tags=["tv", "warning"],
                )
            return "marked"

        if self.state.is_past_grace_period(series.id, self.grace_days):
            size_str = self.format_size(series.size_on_disk)
            self.logger.info(f"Deleting '{series.title}' ({size_str}) - grace period expired")
            if not self.dry_run:
                self.delete_series_files(series)
                self.state.remove(series.id)
                if self.ntfy:
                    self.ntfy.send(
                        title="Anime Deleted",
                        message=f"'{series.title}' ({size_str}) has been deleted.",
                        tags=["tv", "x"],
                    )
            return "deleted"

        pending = self.state.pending[series.id]
        marked_date = datetime.fromisoformat(pending.marked_date)
        days_remaining = self.grace_days - (datetime.now() - marked_date).days
        self.logger.debug(f"'{series.title}' pending deletion, {days_remaining} days remaining")
        return "pending"

    def run(self, target_series: Optional[str] = None) -> dict:
        stats = {
            "watched_recently": 0,
            "watched_by_others": 0,
            "marked": 0,
            "pending": 0,
            "deleted": 0,
            "rescued": 0,
            "skipped_no_files": 0,
            "skipped_whitelisted": 0,
            "skipped_not_ended": 0,
            "skipped_not_found": 0,
            "skipped_not_fully_watched": 0,
            "skipped_no_watch_date": 0,
            "errors": 0,
        }

        self.logger.info("Fetching series from Sonarr...")
        all_series = self.sonarr.get_series()
        self.logger.info(f"Found {len(all_series)} series")

        if target_series:
            all_series = [s for s in all_series if target_series.lower() in s.title.lower()]
            self.logger.info(f"Filtered to {len(all_series)} series matching '{target_series}'")

        for series in all_series:
            try:
                result = self.process_series(series)
                stats[result] = stats.get(result, 0) + 1
            except Exception as e:
                self.logger.error(f"Error processing '{series.title}': {e}")
                stats["errors"] += 1

        if not self.dry_run:
            self.state.save()

        return stats


def load_secret_file(path: str) -> str:
    with open(path) as f:
        content = f.read().strip()
        if "=" in content:
            return content.split("=", 1)[1]
        return content


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Clean up fully watched anime series from Sonarr based on Jellyfin watch history"
    )
    parser.add_argument("--dry-run", action="store_true", help="Show what would be done without making changes")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging")
    parser.add_argument("--threshold", type=int, help="Days since last watch to consider for cleanup")
    parser.add_argument("--grace-period", type=int, help="Days to wait before deletion after marking")
    parser.add_argument("--confirm", action="store_true", help="Require confirmation before deletion")
    parser.add_argument("--series", type=str, help="Target specific series (partial match)")

    parser.add_argument("--sonarr-url", type=str, help="Sonarr URL")
    parser.add_argument("--sonarr-api-key-file", type=str, help="Path to Sonarr API key file")
    parser.add_argument("--jellyfin-url", type=str, help="Jellyfin URL")
    parser.add_argument("--jellyfin-api-key-file", type=str, help="Path to Jellyfin API key file")
    parser.add_argument("--jellyfin-username", type=str, help="Jellyfin username to check watch status for")
    parser.add_argument("--state-file", type=str, help="Path to state file")
    parser.add_argument("--ntfy-topic-file", type=str, help="Path to ntfy topic file")
    parser.add_argument("--whitelist-file", type=str, help="Path to whitelist file (one title per line)")

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    logger = logging.getLogger("main")

    sonarr_url = args.sonarr_url or os.environ.get("SONARR_URL")
    sonarr_api_key_file = args.sonarr_api_key_file or os.environ.get("SONARR_API_KEY_FILE")
    jellyfin_url = args.jellyfin_url or os.environ.get("JELLYFIN_URL")
    jellyfin_api_key_file = args.jellyfin_api_key_file or os.environ.get("JELLYFIN_API_KEY_FILE")
    jellyfin_username = args.jellyfin_username or os.environ.get("JELLYFIN_USERNAME")
    state_file = args.state_file or os.environ.get("STATE_FILE", "/var/lib/sonarr-anime-cleanup/state.json")
    ntfy_topic_file = args.ntfy_topic_file or os.environ.get("NTFY_TOPIC_FILE")
    whitelist_file = args.whitelist_file or os.environ.get("WHITELIST_FILE")

    threshold = args.threshold if args.threshold is not None else int(os.environ.get("THRESHOLD_DAYS", "365"))
    grace_period = args.grace_period if args.grace_period is not None else int(os.environ.get("GRACE_PERIOD_DAYS", "7"))
    dry_run = args.dry_run or os.environ.get("DRY_RUN", "false").lower() == "true"

    if not sonarr_url or not sonarr_api_key_file:
        logger.error("Sonarr URL and API key file are required")
        sys.exit(1)

    if not jellyfin_url or not jellyfin_api_key_file:
        logger.error("Jellyfin URL and API key file are required")
        sys.exit(1)

    if not jellyfin_username:
        logger.error("Jellyfin username is required")
        sys.exit(1)

    sonarr_api_key = load_secret_file(sonarr_api_key_file)
    sonarr = SonarrClient(sonarr_url, sonarr_api_key)

    jellyfin_api_key = load_secret_file(jellyfin_api_key_file)
    jellyfin = JellyfinClient(jellyfin_url, jellyfin_api_key, jellyfin_username)
    logger.info(f"Jellyfin client configured (user: {jellyfin_username})")

    ntfy = None
    if ntfy_topic_file:
        ntfy_topic = load_secret_file(ntfy_topic_file)
        ntfy = NtfyClient(ntfy_topic)
        logger.info("ntfy notifications enabled")

    state = StateManager(Path(state_file))
    logger.info(f"State file: {state_file} ({len(state.pending)} pending deletions)")

    whitelist: set[str] = set()
    if whitelist_file and Path(whitelist_file).exists():
        with open(whitelist_file) as f:
            whitelist = {line.strip().lower() for line in f if line.strip()}
        logger.info(f"Loaded {len(whitelist)} whitelisted titles")

    manager = CleanupManager(
        sonarr=sonarr,
        jellyfin=jellyfin,
        state=state,
        ntfy=ntfy,
        threshold_days=threshold,
        grace_days=grace_period,
        dry_run=dry_run,
        whitelist=whitelist,
    )

    if dry_run:
        logger.info("DRY RUN MODE - no changes will be made")

    if args.confirm and not dry_run:
        confirm = input("This will delete files from disk. Continue? [y/N] ")
        if confirm.lower() != "y":
            logger.info("Aborted by user")
            sys.exit(0)

    stats = manager.run(target_series=args.series)

    logger.info("=" * 50)
    logger.info("Summary:")
    logger.info(f"  Watched recently (kept):    {stats['watched_recently']}")
    logger.info(f"  Watched by others (kept):   {stats['watched_by_others']}")
    logger.info(f"  Newly marked:               {stats['marked']}")
    logger.info(f"  Pending deletion:           {stats['pending']}")
    logger.info(f"  Deleted:                    {stats['deleted']}")
    logger.info(f"  Rescued:                    {stats['rescued']}")
    logger.info(f"  Skipped (no files):         {stats['skipped_no_files']}")
    logger.info(f"  Skipped (whitelisted):      {stats['skipped_whitelisted']}")
    logger.info(f"  Skipped (not ended):        {stats['skipped_not_ended']}")
    logger.info(f"  Skipped (not in Jellyfin):  {stats['skipped_not_found']}")
    logger.info(f"  Skipped (not fully watched): {stats['skipped_not_fully_watched']}")
    logger.info(f"  Skipped (no watch date):    {stats['skipped_no_watch_date']}")
    logger.info(f"  Errors:                     {stats['errors']}")


if __name__ == "__main__":
    main()
