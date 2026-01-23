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
from urllib.parse import urljoin

import requests


@dataclass
class SeriesInfo:
    id: int
    title: str
    path: str
    size_on_disk: int
    monitored: bool
    added: Optional[datetime]


@dataclass
class WatchInfo:
    last_watched: Optional[datetime]
    user: str
    source: str


class SonarrClient:
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip("/")
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers["X-Api-Key"] = api_key
        self.logger = logging.getLogger("sonarr")

    def get_series(self) -> list[SeriesInfo]:
        resp = self.session.get(f"{self.url}/api/v3/series")
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
                added=added,
            ))
        return series_list

    def get_episode_files(self, series_id: int) -> list[dict]:
        resp = self.session.get(f"{self.url}/api/v3/episodefile", params={"seriesId": series_id})
        resp.raise_for_status()
        return resp.json()

    def get_newest_episode_date(self, series_id: int) -> Optional[datetime]:
        episode_files = self.get_episode_files(series_id)
        newest = None
        for ef in episode_files:
            date_added = ef.get("dateAdded")
            if date_added:
                dt = datetime.fromisoformat(date_added.replace("Z", "+00:00")).replace(tzinfo=None)
                if newest is None or dt > newest:
                    newest = dt
        return newest

    def delete_episode_files(self, file_ids: list[int]) -> None:
        for file_id in file_ids:
            resp = self.session.delete(f"{self.url}/api/v3/episodefile/{file_id}")
            resp.raise_for_status()

    def unmonitor_series(self, series_id: int) -> None:
        resp = self.session.get(f"{self.url}/api/v3/series/{series_id}")
        resp.raise_for_status()
        series_data = resp.json()
        series_data["monitored"] = False
        resp = self.session.put(f"{self.url}/api/v3/series/{series_id}", json=series_data)
        resp.raise_for_status()


class JellyfinClient:
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip("/")
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers["X-Emby-Token"] = api_key
        self.logger = logging.getLogger("jellyfin")

    def get_users(self) -> list[dict]:
        resp = self.session.get(f"{self.url}/Users")
        resp.raise_for_status()
        return resp.json()

    def _find_series_id(self, user_id: str, series_name: str) -> Optional[str]:
        resp = self.session.get(
            f"{self.url}/Users/{user_id}/Items",
            params={
                "IncludeItemTypes": "Series",
                "Recursive": True,
                "SearchTerm": series_name,
            }
        )
        resp.raise_for_status()
        items = resp.json().get("Items", [])
        for item in items:
            if item.get("Name", "").lower() == series_name.lower():
                return item.get("Id")
        return None

    def get_series_last_watched(self, series_name: str) -> Optional[WatchInfo]:
        users = self.get_users()
        latest_watch: Optional[WatchInfo] = None

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
                    }
                )
                resp.raise_for_status()
                episodes = resp.json().get("Items", [])

                if episodes:
                    user_data = episodes[0].get("UserData", {})
                    last_played_str = user_data.get("LastPlayedDate")
                    if last_played_str:
                        last_played = datetime.fromisoformat(last_played_str.replace("Z", "+00:00"))
                        last_played = last_played.replace(tzinfo=None)
                        self.logger.debug(f"User {user_name} last watched '{series_name}' on {last_played}")
                        if latest_watch is None or last_played > latest_watch.last_watched:
                            latest_watch = WatchInfo(last_watched=last_played, user=user_name, source="jellyfin")
            except Exception as e:
                self.logger.warning(f"Error fetching Jellyfin data for user {user_name}: {e}")

        return latest_watch


class PlexClient:
    def __init__(self, url: str, token: str):
        self.url = url.rstrip("/")
        self.token = token
        self.session = requests.Session()
        self.session.headers["X-Plex-Token"] = token
        self.session.headers["Accept"] = "application/json"
        self.logger = logging.getLogger("plex")
        self._history_cache: Optional[dict[str, WatchInfo]] = None

    def _build_history_cache(self) -> dict[str, WatchInfo]:
        cache: dict[str, WatchInfo] = {}
        try:
            self.logger.info(f"Fetching Plex history from {self.url}/status/sessions/history/all")
            resp = self.session.get(
                f"{self.url}/status/sessions/history/all",
                params={"sort": "viewedAt:desc"}
            )
            resp.raise_for_status()
            data = resp.json()
            entries = data.get("MediaContainer", {}).get("Metadata", [])
            self.logger.info(f"Plex returned {len(entries)} history entries")

            for entry in entries:
                if entry.get("type") != "episode":
                    continue
                grandparent_title = entry.get("grandparentTitle", "").lower()
                if not grandparent_title:
                    continue

                viewed_at = entry.get("viewedAt")
                account_id = entry.get("accountID", "unknown")
                if viewed_at and grandparent_title not in cache:
                    cache[grandparent_title] = WatchInfo(
                        last_watched=datetime.fromtimestamp(viewed_at),
                        user=f"account:{account_id}",
                        source="plex"
                    )
            self.logger.info(f"Plex history cache built with {len(cache)} unique series")
        except Exception as e:
            self.logger.warning(f"Error building Plex history cache: {e}", exc_info=True)
        return cache

    def get_series_last_watched(self, series_name: str) -> Optional[WatchInfo]:
        if self._history_cache is None:
            self._history_cache = self._build_history_cache()

        watch_info = self._history_cache.get(series_name.lower())
        if watch_info:
            self.logger.debug(f"Plex: '{series_name}' last viewed on {watch_info.last_watched}")
        return watch_info


class NtfyClient:
    def __init__(self, topic: str, server_url: str = "https://ntfy.sh"):
        self.topic = topic
        self.server_url = server_url.rstrip("/")
        self.logger = logging.getLogger("ntfy")

    def send(self, title: str, message: str, priority: str = "default", tags: list[str] = None) -> None:
        try:
            headers = {"Title": title, "Priority": priority}
            if tags:
                headers["Tags"] = ",".join(tags)
            resp = requests.post(
                f"{self.server_url}/{self.topic}",
                data=message.encode("utf-8"),
                headers=headers
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
        jellyfin: Optional[JellyfinClient],
        plex: Optional[PlexClient],
        state: StateManager,
        ntfy: Optional[NtfyClient],
        threshold_days: int,
        grace_days: int,
        dry_run: bool,
    ):
        self.sonarr = sonarr
        self.jellyfin = jellyfin
        self.plex = plex
        self.state = state
        self.ntfy = ntfy
        self.threshold_days = threshold_days
        self.grace_days = grace_days
        self.dry_run = dry_run
        self.logger = logging.getLogger("cleanup")

    def get_last_watched(self, series_title: str) -> Optional[WatchInfo]:
        latest: Optional[WatchInfo] = None

        if self.jellyfin:
            jf_watch = self.jellyfin.get_series_last_watched(series_title)
            if jf_watch and (latest is None or jf_watch.last_watched > latest.last_watched):
                latest = jf_watch

        if self.plex:
            plex_watch = self.plex.get_series_last_watched(series_title)
            if plex_watch and (latest is None or plex_watch.last_watched > latest.last_watched):
                latest = plex_watch

        return latest

    def is_unwatched(self, watch_info: Optional[WatchInfo]) -> bool:
        if watch_info is None:
            return True
        threshold_date = datetime.now() - timedelta(days=self.threshold_days)
        return watch_info.last_watched < threshold_date

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

        watch_info = self.get_last_watched(series.title)

        if watch_info is None:
            newest_episode = self.sonarr.get_newest_episode_date(series.id)
            check_date = newest_episode or series.added
            if check_date:
                days_since = (datetime.now() - check_date).days
                if days_since < self.threshold_days:
                    date_type = "episode added" if newest_episode else "series added"
                    self.logger.debug(f"'{series.title}' never watched, {date_type} {days_since} days ago, skipping (< {self.threshold_days} day threshold)")
                    return "skipped_new"

        if not self.is_unwatched(watch_info):
            days_ago = (datetime.now() - watch_info.last_watched).days
            self.logger.info(f"'{series.title}' - watched by {watch_info.user} ({watch_info.source}) {days_ago} days ago")
            if series.id in self.state.pending:
                self.logger.info(f"  -> Removing from deletion queue (watched during grace period)")
                self.state.remove(series.id)
                return "rescued"
            return "watched"

        days_since = "never" if watch_info is None else f"{(datetime.now() - watch_info.last_watched).days} days ago"
        self.logger.debug(f"'{series.title}' last watched: {days_since}")

        if series.id not in self.state.pending:
            newly_marked = self.state.mark_for_deletion(series)
            if newly_marked:
                size_str = self.format_size(series.size_on_disk)
                self.logger.info(f"Marking '{series.title}' for deletion ({size_str}, last watched: {days_since})")
                if self.ntfy and not self.dry_run:
                    self.ntfy.send(
                        title="Series Marked for Cleanup",
                        message=f"'{series.title}' ({size_str}) will be deleted in {self.grace_days} days.\nLast watched: {days_since}",
                        tags=["tv", "warning"],
                    )
                return "marked"
            return "already_marked"

        if self.state.is_past_grace_period(series.id, self.grace_days):
            size_str = self.format_size(series.size_on_disk)
            self.logger.info(f"Deleting '{series.title}' ({size_str}) - grace period expired")
            if not self.dry_run:
                self.delete_series_files(series)
                self.state.remove(series.id)
                if self.ntfy:
                    self.ntfy.send(
                        title="Series Deleted",
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
            "watched": 0,
            "marked": 0,
            "pending": 0,
            "deleted": 0,
            "rescued": 0,
            "skipped_no_files": 0,
            "skipped_new": 0,
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
        description="Clean up TV series from Sonarr that haven't been watched in Jellyfin/Plex"
    )
    parser.add_argument("--dry-run", action="store_true", help="Show what would be done without making changes")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging")
    parser.add_argument("--threshold", type=int, help="Days since last watch to consider unwatched")
    parser.add_argument("--grace-period", type=int, help="Days to wait before deletion after marking")
    parser.add_argument("--confirm", action="store_true", help="Require confirmation before deletion")
    parser.add_argument("--series", type=str, help="Target specific series (partial match)")

    parser.add_argument("--sonarr-url", type=str, help="Sonarr URL")
    parser.add_argument("--sonarr-api-key-file", type=str, help="Path to Sonarr API key file")
    parser.add_argument("--jellyfin-url", type=str, help="Jellyfin URL")
    parser.add_argument("--jellyfin-api-key-file", type=str, help="Path to Jellyfin API key file")
    parser.add_argument("--plex-url", type=str, help="Plex URL")
    parser.add_argument("--plex-token-file", type=str, help="Path to Plex token file")
    parser.add_argument("--state-file", type=str, help="Path to state file")
    parser.add_argument("--ntfy-topic-file", type=str, help="Path to ntfy topic file")

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
    plex_url = args.plex_url or os.environ.get("PLEX_URL")
    plex_token_file = args.plex_token_file or os.environ.get("PLEX_TOKEN_FILE")
    state_file = args.state_file or os.environ.get("STATE_FILE", "/var/lib/sonarr-cleanup/state.json")
    ntfy_topic_file = args.ntfy_topic_file or os.environ.get("NTFY_TOPIC_FILE")

    threshold = args.threshold or int(os.environ.get("THRESHOLD_DAYS", "730"))
    grace_period = args.grace_period or int(os.environ.get("GRACE_PERIOD_DAYS", "7"))
    dry_run = args.dry_run or os.environ.get("DRY_RUN", "false").lower() == "true"

    if not sonarr_url or not sonarr_api_key_file:
        logger.error("Sonarr URL and API key file are required")
        sys.exit(1)

    sonarr_api_key = load_secret_file(sonarr_api_key_file)
    sonarr = SonarrClient(sonarr_url, sonarr_api_key)

    jellyfin = None
    if jellyfin_url and jellyfin_api_key_file:
        jellyfin_api_key = load_secret_file(jellyfin_api_key_file)
        jellyfin = JellyfinClient(jellyfin_url, jellyfin_api_key)
        logger.info("Jellyfin client configured")

    plex = None
    if plex_url and plex_token_file:
        plex_token = load_secret_file(plex_token_file)
        plex = PlexClient(plex_url, plex_token)
        logger.info("Plex client configured")

    if not jellyfin and not plex:
        logger.error("At least one media server (Jellyfin or Plex) must be configured")
        sys.exit(1)

    ntfy = None
    if ntfy_topic_file:
        ntfy_topic = load_secret_file(ntfy_topic_file)
        ntfy = NtfyClient(ntfy_topic)
        logger.info("ntfy notifications enabled")

    state = StateManager(Path(state_file))
    logger.info(f"State file: {state_file} ({len(state.pending)} pending deletions)")

    manager = CleanupManager(
        sonarr=sonarr,
        jellyfin=jellyfin,
        plex=plex,
        state=state,
        ntfy=ntfy,
        threshold_days=threshold,
        grace_days=grace_period,
        dry_run=dry_run,
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
    logger.info(f"  Watched (kept):     {stats['watched']}")
    logger.info(f"  Newly marked:       {stats['marked']}")
    logger.info(f"  Pending deletion:   {stats['pending']}")
    logger.info(f"  Deleted:            {stats['deleted']}")
    logger.info(f"  Rescued:            {stats['rescued']}")
    logger.info(f"  Skipped (no files): {stats['skipped_no_files']}")
    logger.info(f"  Skipped (new):      {stats['skipped_new']}")
    logger.info(f"  Errors:             {stats['errors']}")


if __name__ == "__main__":
    main()
