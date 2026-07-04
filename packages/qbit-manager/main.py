#!/usr/bin/env python3

import argparse
import json
import logging
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional

import qbittorrentapi


def is_public(torrent) -> bool:
    return not getattr(torrent, "private", False)


@dataclass
class QBittorrentConfig:
    host: str = "localhost"
    port: int = 8080
    username: str = "admin"
    password: str = "admin"
    public_ratio_limit: float = 2.0
    upload_limit_downloading: int = 200000
    arr_categories: List[str] = field(default_factory=lambda: ["sonarr-done", "sonarr-anime-done", "radarr-done", "radarr-anime-done"])
    categorize_only: bool = False
    dry_run: bool = False


class QBittorrentManager:
    def __init__(self, config: QBittorrentConfig):
        self.config = config
        self.client: Optional[qbittorrentapi.Client] = None
        self.logger = logging.getLogger(__name__)

    def connect(self) -> bool:
        try:
            self.client = qbittorrentapi.Client(
                host=self.config.host,
                port=self.config.port,
                username=self.config.username,
                password=self.config.password,
            )
            self.client.auth_log_in()
            self.logger.debug(f"Connected to qBittorrent at {self.config.host}:{self.config.port}")
            return True
        except qbittorrentapi.LoginFailed as e:
            self.logger.error(f"Login failed: {e}")
            return False
        except Exception as e:
            self.logger.error(f"Connection failed: {e}")
            return False

    def disconnect(self) -> None:
        if self.client:
            try:
                self.client.auth_log_out()
                self.logger.debug("Disconnected from qBittorrent")
            except Exception as e:
                self.logger.warning(f"Error during logout: {e}")

    def ensure_categories(self) -> None:
        if not self.client:
            raise RuntimeError("Client not connected")
        
        categories = self.client.torrent_categories.categories
        
        for category in ["Public", "Private"]:
            if category not in categories:
                if not self.config.dry_run:
                    self.client.torrent_categories.create_category(name=category)
                self.logger.info(f"{'Would create' if self.config.dry_run else 'Created'} {category} category")
            else:
                self.logger.debug(f"Category {category} already exists")

    def categorize_torrents(self) -> None:
        if not self.client:
            raise RuntimeError("Client not connected")
        
        uncategorized_torrents = self.client.torrents_info(category="")
        
        if not uncategorized_torrents:
            self.logger.debug("No uncategorized torrents found")
            return
        
        self.logger.info(f"Found {len(uncategorized_torrents)} uncategorized torrents")
        
        for torrent in uncategorized_torrents:
            is_private = torrent.private if hasattr(torrent, 'private') else False
            category = "Private" if is_private else "Public"
            
            if not self.config.dry_run:
                self.client.torrents_set_category(category, torrent.hash)
            
            self.logger.info(
                f"{'Would set' if self.config.dry_run else 'Set'} {category} category for {torrent.name}"
            )

    def manage_share_limits(self) -> None:
        if not self.client:
            raise RuntimeError("Client not connected")
        
        public_torrents = [t for t in self.client.torrents_info() if is_public(t)]

        if public_torrents and not self.config.dry_run:
            self.logger.debug(f"Setting share limits for {len(public_torrents)} public torrents")
            self.client.torrents_set_share_limits(
                ratio_limit=self.config.public_ratio_limit,
                inactive_seeding_time_limit=-1,
                seeding_time_limit=-1,
                share_limit_action="Stop",
                torrent_hashes=[t.hash for t in public_torrents],
            )

    def manage_upload_limits(self) -> None:
        if not self.client:
            raise RuntimeError("Client not connected")
        
        downloading_public = [
            t
            for t in self.client.torrents_info(status_filter="downloading")
            if is_public(t)
        ]

        if downloading_public and not self.config.dry_run:
            self.logger.debug(f"Setting upload limits for {len(downloading_public)} downloading public torrents")
            self.client.torrents_set_upload_limit(
                limit=self.config.upload_limit_downloading,
                torrent_hashes=[t.hash for t in downloading_public],
            )

        seeding_public = [
            t
            for t in self.client.torrents_info(status_filter="seeding")
            if is_public(t)
        ]

        if seeding_public and not self.config.dry_run:
            self.logger.debug(f"Removing upload limits for {len(seeding_public)} seeding public torrents")
            self.client.torrents_set_upload_limit(
                limit=-1, torrent_hashes=[t.hash for t in seeding_public]
            )

    def cleanup_completed_torrents(self) -> None:
        if not self.client:
            raise RuntimeError("Client not connected")
        
        arr_categories = set(self.config.arr_categories)
        completed_states = ["stoppedUP"]

        delete_with_files = []
        delete_keep_files = []

        for t in self.client.torrents_info():
            if t.state not in completed_states or t.progress != 1.0:
                continue

            if t.category in arr_categories:
                delete_with_files.append(t)
            elif is_public(t):
                delete_keep_files.append(t)

        for torrents, delete_files in ((delete_with_files, True), (delete_keep_files, False)):
            if not torrents:
                continue

            files_action = "files deleted" if delete_files else "files kept"
            self.logger.info(
                f"{'Would remove' if self.config.dry_run else 'Removing'} "
                f"{len(torrents)} completed torrents ({files_action})"
            )

            for t in torrents:
                self.logger.info(f"  - {t.name[:80]}")

            if not self.config.dry_run:
                self.client.torrents_delete(
                    delete_files=delete_files,
                    torrent_hashes=[t.hash for t in torrents],
                )

        total_removed = len(delete_with_files) + len(delete_keep_files)
        if total_removed > 0:
            self.logger.info(f"Total completed torrents removed: {total_removed}")
        else:
            self.logger.debug("No completed torrents found for cleanup")

    def prioritize_private_torrents(self) -> None:
        if not self.client:
            raise RuntimeError("Client not connected")
        
        private_downloading = [
            t
            for t in self.client.torrents_info(status_filter="downloading")
            if not is_public(t)
        ]

        if private_downloading and not self.config.dry_run:
            self.logger.debug(f"Setting high priority for {len(private_downloading)} private torrents")
            self.client.torrents_top_priority([t.hash for t in private_downloading])

    def run_management_cycle(self) -> None:
        if not self.connect():
            sys.exit(1)
        
        try:
            self.ensure_categories()
            self.categorize_torrents()
            
            if self.config.categorize_only:
                self.manage_share_limits()
                self.prioritize_private_torrents()
            else:
                self.manage_share_limits()
                self.manage_upload_limits()
                self.cleanup_completed_torrents()
                self.prioritize_private_torrents()
            
        except Exception as e:
            self.logger.error(f"Error during management cycle: {e}")
            raise
        finally:
            self.disconnect()


def load_config_from_file(config_path: Path) -> dict:
    if not config_path.exists():
        return {}
    
    with open(config_path) as f:
        return json.load(f)


def load_config_from_env() -> dict:
    config = {}
    env_mappings = {
        'QBIT_HOST': 'host',
        'QBIT_PORT': 'port',
        'QBIT_USERNAME': 'username',
        'QBIT_PASSWORD': 'password',
        'QBIT_PUBLIC_RATIO': 'public_ratio_limit',
        'QBIT_UPLOAD_LIMIT': 'upload_limit_downloading',
        'QBIT_ARR_CATEGORIES': 'arr_categories',
    }
    
    for env_var, config_key in env_mappings.items():
        value = os.environ.get(env_var)
        if value:
            if config_key in ['port', 'upload_limit_downloading']:
                config[config_key] = int(value)
            elif config_key == 'public_ratio_limit':
                config[config_key] = float(value)
            elif config_key == 'arr_categories':
                config[config_key] = [cat.strip() for cat in value.split(',')]
            else:
                config[config_key] = value
    
    return config


def setup_logging(verbose: bool = False, quiet: bool = False) -> None:
    level = logging.WARNING if quiet else (logging.DEBUG if verbose else logging.INFO)
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="qBittorrent management tool for categorization and automation"
    )
    parser.add_argument(
        "-c", "--config",
        type=Path,
        help="Path to JSON configuration file"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes"
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Only log warnings and errors"
    )
    parser.add_argument(
        "--categorize-only",
        action="store_true",
        help="Only run categorization, skip cleanup and other management tasks"
    )
    
    args = parser.parse_args()
    setup_logging(verbose=args.verbose, quiet=args.quiet)
    
    config_dict = {}
    
    if args.config:
        config_dict.update(load_config_from_file(args.config))
    
    config_dict.update(load_config_from_env())
    
    if args.dry_run:
        config_dict['dry_run'] = True
    
    if args.categorize_only:
        config_dict['categorize_only'] = True
    
    config = QBittorrentConfig(**config_dict)
    
    manager = QBittorrentManager(config)
    manager.run_management_cycle()


if __name__ == "__main__":
    main()
