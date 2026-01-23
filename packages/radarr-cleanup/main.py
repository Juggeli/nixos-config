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


@dataclass
class MovieInfo:
    id: int
    title: str
    path: str
    size_on_disk: int
    monitored: bool
    added: Optional[datetime]
    has_file: bool
    movie_file_id: Optional[int]


@dataclass
class WatchInfo:
    last_watched: Optional[datetime]
    user: str
    source: str


class RadarrClient:
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip("/")
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers["X-Api-Key"] = api_key
        self.logger = logging.getLogger("radarr")

    def get_movies(self) -> list[MovieInfo]:
        resp = self.session.get(f"{self.url}/api/v3/movie")
        resp.raise_for_status()
        movies = []
        for m in resp.json():
            added = None
            if m.get("added"):
                added = datetime.fromisoformat(m["added"].replace("Z", "+00:00")).replace(tzinfo=None)
            movie_file = m.get("movieFile", {})
            movies.append(MovieInfo(
                id=m["id"],
                title=m["title"],
                path=m.get("path", ""),
                size_on_disk=m.get("sizeOnDisk", 0),
                monitored=m["monitored"],
                added=added,
                has_file=m.get("hasFile", False),
                movie_file_id=movie_file.get("id") if movie_file else None,
            ))
        return movies

    def get_movie_file_date(self, movie_id: int) -> Optional[datetime]:
        resp = self.session.get(f"{self.url}/api/v3/movie/{movie_id}")
        resp.raise_for_status()
        movie = resp.json()
        movie_file = movie.get("movieFile", {})
        date_added = movie_file.get("dateAdded")
        if date_added:
            return datetime.fromisoformat(date_added.replace("Z", "+00:00")).replace(tzinfo=None)
        return None

    def delete_movie_file(self, movie_file_id: int) -> None:
        resp = self.session.delete(f"{self.url}/api/v3/moviefile/{movie_file_id}")
        resp.raise_for_status()

    def unmonitor_movie(self, movie_id: int) -> None:
        resp = self.session.get(f"{self.url}/api/v3/movie/{movie_id}")
        resp.raise_for_status()
        movie_data = resp.json()
        movie_data["monitored"] = False
        resp = self.session.put(f"{self.url}/api/v3/movie/{movie_id}", json=movie_data)
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

    def get_movie_last_watched(self, movie_title: str) -> Optional[WatchInfo]:
        users = self.get_users()
        latest_watch: Optional[WatchInfo] = None

        for user in users:
            user_id = user["Id"]
            user_name = user["Name"]

            try:
                resp = self.session.get(
                    f"{self.url}/Users/{user_id}/Items",
                    params={
                        "IncludeItemTypes": "Movie",
                        "Recursive": True,
                        "SearchTerm": movie_title,
                        "Fields": "UserData",
                    }
                )
                resp.raise_for_status()
                items = resp.json().get("Items", [])

                for item in items:
                    if item.get("Name", "").lower() == movie_title.lower():
                        user_data = item.get("UserData", {})
                        last_played_str = user_data.get("LastPlayedDate")
                        if last_played_str:
                            last_played = datetime.fromisoformat(last_played_str.replace("Z", "+00:00"))
                            last_played = last_played.replace(tzinfo=None)
                            self.logger.debug(f"User {user_name} last watched '{movie_title}' on {last_played}")
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
                if entry.get("type") != "movie":
                    continue
                title = entry.get("title", "").lower()
                if not title:
                    continue

                viewed_at = entry.get("viewedAt")
                account_id = entry.get("accountID", "unknown")
                if viewed_at and title not in cache:
                    cache[title] = WatchInfo(
                        last_watched=datetime.fromtimestamp(viewed_at),
                        user=f"account:{account_id}",
                        source="plex"
                    )
            self.logger.info(f"Plex history cache built with {len(cache)} unique movies")
        except Exception as e:
            self.logger.warning(f"Error building Plex history cache: {e}", exc_info=True)
        return cache

    def get_movie_last_watched(self, movie_title: str) -> Optional[WatchInfo]:
        if self._history_cache is None:
            self._history_cache = self._build_history_cache()

        watch_info = self._history_cache.get(movie_title.lower())
        if watch_info:
            self.logger.debug(f"Plex: '{movie_title}' last viewed on {watch_info.last_watched}")
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
    movie_id: int
    movie_title: str
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
                for movie_id_str, entry in data.get("pending", {}).items():
                    movie_id = int(movie_id_str)
                    self.pending[movie_id] = PendingDeletion(
                        movie_id=movie_id,
                        movie_title=entry["movie_title"],
                        marked_date=entry["marked_date"],
                        size_bytes=entry.get("size_bytes", 0),
                    )

    def save(self) -> None:
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        data = {
            "pending": {
                str(p.movie_id): {
                    "movie_title": p.movie_title,
                    "marked_date": p.marked_date,
                    "size_bytes": p.size_bytes,
                }
                for p in self.pending.values()
            }
        }
        with open(self.state_file, "w") as f:
            json.dump(data, f, indent=2)

    def mark_for_deletion(self, movie: MovieInfo) -> bool:
        if movie.id in self.pending:
            return False
        self.pending[movie.id] = PendingDeletion(
            movie_id=movie.id,
            movie_title=movie.title,
            marked_date=datetime.now().isoformat(),
            size_bytes=movie.size_on_disk,
        )
        return True

    def is_past_grace_period(self, movie_id: int, grace_days: int) -> bool:
        if movie_id not in self.pending:
            return False
        marked_date = datetime.fromisoformat(self.pending[movie_id].marked_date)
        return datetime.now() - marked_date >= timedelta(days=grace_days)

    def remove(self, movie_id: int) -> None:
        self.pending.pop(movie_id, None)


class CleanupManager:
    def __init__(
        self,
        radarr: RadarrClient,
        jellyfin: Optional[JellyfinClient],
        plex: Optional[PlexClient],
        state: StateManager,
        ntfy: Optional[NtfyClient],
        threshold_days: int,
        grace_days: int,
        dry_run: bool,
    ):
        self.radarr = radarr
        self.jellyfin = jellyfin
        self.plex = plex
        self.state = state
        self.ntfy = ntfy
        self.threshold_days = threshold_days
        self.grace_days = grace_days
        self.dry_run = dry_run
        self.logger = logging.getLogger("cleanup")

    def get_last_watched(self, movie_title: str) -> Optional[WatchInfo]:
        latest: Optional[WatchInfo] = None

        if self.jellyfin:
            jf_watch = self.jellyfin.get_movie_last_watched(movie_title)
            if jf_watch and (latest is None or jf_watch.last_watched > latest.last_watched):
                latest = jf_watch

        if self.plex:
            plex_watch = self.plex.get_movie_last_watched(movie_title)
            if plex_watch and (latest is None or plex_watch.last_watched > latest.last_watched):
                latest = plex_watch

        return latest

    def is_unwatched(self, watch_info: Optional[WatchInfo]) -> bool:
        if watch_info is None:
            return True
        threshold_date = datetime.now() - timedelta(days=self.threshold_days)
        return watch_info.last_watched < threshold_date

    def delete_movie_file(self, movie: MovieInfo) -> None:
        if movie.movie_file_id:
            self.logger.info(f"Deleting movie file for '{movie.title}'")
            if not self.dry_run:
                self.radarr.delete_movie_file(movie.movie_file_id)

        self.logger.info(f"Unmonitoring movie '{movie.title}'")
        if not self.dry_run:
            self.radarr.unmonitor_movie(movie.id)

    def format_size(self, size_bytes: int) -> str:
        for unit in ["B", "KB", "MB", "GB", "TB"]:
            if size_bytes < 1024:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024
        return f"{size_bytes:.2f} PB"

    def process_movie(self, movie: MovieInfo) -> str:
        if not movie.has_file or movie.size_on_disk == 0:
            return "skipped_no_files"

        watch_info = self.get_last_watched(movie.title)

        if watch_info is None:
            file_date = self.radarr.get_movie_file_date(movie.id)
            check_date = file_date or movie.added
            if check_date:
                days_since = (datetime.now() - check_date).days
                if days_since < self.threshold_days:
                    date_type = "file added" if file_date else "movie added"
                    self.logger.debug(f"'{movie.title}' never watched, {date_type} {days_since} days ago, skipping (< {self.threshold_days} day threshold)")
                    return "skipped_new"

        if not self.is_unwatched(watch_info):
            days_ago = (datetime.now() - watch_info.last_watched).days
            self.logger.info(f"'{movie.title}' - watched by {watch_info.user} ({watch_info.source}) {days_ago} days ago")
            if movie.id in self.state.pending:
                self.logger.info(f"  -> Removing from deletion queue (watched during grace period)")
                self.state.remove(movie.id)
                return "rescued"
            return "watched"

        days_since = "never" if watch_info is None else f"{(datetime.now() - watch_info.last_watched).days} days ago"
        self.logger.debug(f"'{movie.title}' last watched: {days_since}")

        if movie.id not in self.state.pending:
            newly_marked = self.state.mark_for_deletion(movie)
            if newly_marked:
                size_str = self.format_size(movie.size_on_disk)
                self.logger.info(f"Marking '{movie.title}' for deletion ({size_str}, last watched: {days_since})")
                if self.ntfy and not self.dry_run:
                    self.ntfy.send(
                        title="Movie Marked for Cleanup",
                        message=f"'{movie.title}' ({size_str}) will be deleted in {self.grace_days} days.\nLast watched: {days_since}",
                        tags=["movie_camera", "warning"],
                    )
                return "marked"
            return "already_marked"

        if self.state.is_past_grace_period(movie.id, self.grace_days):
            size_str = self.format_size(movie.size_on_disk)
            self.logger.info(f"Deleting '{movie.title}' ({size_str}) - grace period expired")
            if not self.dry_run:
                self.delete_movie_file(movie)
                self.state.remove(movie.id)
                if self.ntfy:
                    self.ntfy.send(
                        title="Movie Deleted",
                        message=f"'{movie.title}' ({size_str}) has been deleted.",
                        tags=["movie_camera", "x"],
                    )
            return "deleted"

        pending = self.state.pending[movie.id]
        marked_date = datetime.fromisoformat(pending.marked_date)
        days_remaining = self.grace_days - (datetime.now() - marked_date).days
        self.logger.debug(f"'{movie.title}' pending deletion, {days_remaining} days remaining")
        return "pending"

    def run(self, target_movie: Optional[str] = None) -> dict:
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

        self.logger.info("Fetching movies from Radarr...")
        all_movies = self.radarr.get_movies()
        self.logger.info(f"Found {len(all_movies)} movies")

        if target_movie:
            all_movies = [m for m in all_movies if target_movie.lower() in m.title.lower()]
            self.logger.info(f"Filtered to {len(all_movies)} movies matching '{target_movie}'")

        for movie in all_movies:
            try:
                result = self.process_movie(movie)
                stats[result] = stats.get(result, 0) + 1
            except Exception as e:
                self.logger.error(f"Error processing '{movie.title}': {e}")
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
        description="Clean up movies from Radarr that haven't been watched in Jellyfin/Plex"
    )
    parser.add_argument("--dry-run", action="store_true", help="Show what would be done without making changes")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging")
    parser.add_argument("--threshold", type=int, help="Days since last watch to consider unwatched")
    parser.add_argument("--grace-period", type=int, help="Days to wait before deletion after marking")
    parser.add_argument("--confirm", action="store_true", help="Require confirmation before deletion")
    parser.add_argument("--movie", type=str, help="Target specific movie (partial match)")

    parser.add_argument("--radarr-url", type=str, help="Radarr URL")
    parser.add_argument("--radarr-api-key-file", type=str, help="Path to Radarr API key file")
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

    radarr_url = args.radarr_url or os.environ.get("RADARR_URL")
    radarr_api_key_file = args.radarr_api_key_file or os.environ.get("RADARR_API_KEY_FILE")
    jellyfin_url = args.jellyfin_url or os.environ.get("JELLYFIN_URL")
    jellyfin_api_key_file = args.jellyfin_api_key_file or os.environ.get("JELLYFIN_API_KEY_FILE")
    plex_url = args.plex_url or os.environ.get("PLEX_URL")
    plex_token_file = args.plex_token_file or os.environ.get("PLEX_TOKEN_FILE")
    state_file = args.state_file or os.environ.get("STATE_FILE", "/var/lib/radarr-cleanup/state.json")
    ntfy_topic_file = args.ntfy_topic_file or os.environ.get("NTFY_TOPIC_FILE")

    threshold = args.threshold or int(os.environ.get("THRESHOLD_DAYS", "730"))
    grace_period = args.grace_period or int(os.environ.get("GRACE_PERIOD_DAYS", "7"))
    dry_run = args.dry_run or os.environ.get("DRY_RUN", "false").lower() == "true"

    if not radarr_url or not radarr_api_key_file:
        logger.error("Radarr URL and API key file are required")
        sys.exit(1)

    radarr_api_key = load_secret_file(radarr_api_key_file)
    radarr = RadarrClient(radarr_url, radarr_api_key)

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
        radarr=radarr,
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

    stats = manager.run(target_movie=args.movie)

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
