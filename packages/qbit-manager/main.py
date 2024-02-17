import qbittorrentapi

private_trackers = [
    "empornium.sx",
    "landof.tv",
    "passthepopcorn.me",
    "hdbits.org",
    "animebytes.tv",
]


def main():
    client = qbittorrentapi.Client("brr", 8080, "admin", "adminadmin")

    try:
        client.auth_log_in()
    except qbittorrentapi.LoginFailed as e:
        print(e)

    print(f"Total torrents: {client.torrents_count()}")

    # Check and create categories
    categories = client.torrent_categories.categories
    if "Public" not in categories.keys():
        client.torrent_categories.create_category(name="Public")
        print("Created Public category")
    else:
        print("Category Public exists")
    if "Private" not in categories.keys():
        client.torrent_categories.create_category(name="Private")
        print("Created Private category")
    else:
        print("Category Private exists")

    # Categorize uncategorized torrents
    uncategorized_torrents = client.torrents_info(category="")
    print(f"Uncategorized torrents: {len(uncategorized_torrents)}")
    for uncategorized in uncategorized_torrents:
        trackers = client.torrents_trackers(uncategorized.hash)
        # DHT, PeX and LSD count as tracker so the fourth is the real tracker
        has_only_one_tracker = len(trackers) == 4
        has_private_tracker = False

        for tracker in trackers:
            for private_tracker in private_trackers:
                if private_tracker in tracker.url:
                    has_private_tracker = True

        if has_only_one_tracker and has_private_tracker:
            print(f"Setting Private category to {uncategorized.name}")
            client.torrents_set_category("Private", uncategorized.hash)
        else:
            print(f"Setting Public category to {uncategorized.name}")
            client.torrents_set_category("Public", uncategorized.hash)

    # Set share limit for public torrents
    public_torrents = client.torrents_info(category="Public")
    print(f"Public torrents: {len(public_torrents)}")
    client.torrents_set_share_limits(
        ratio_limit=2,
        inactive_seeding_time_limit=-1,
        seeding_time_limit=-1,
        torrent_hashes=map(lambda x: x.hash, public_torrents),
    )

    # Set upload speed limit for downloading public torrents
    downloading_public_torrents = client.torrents_info(
        category="Public", status_filter="downloading"
    )
    print(f"Downloading public torrents: {len(downloading_public_torrents)}")
    client.torrents_set_upload_limit(
        limit=200000,
        torrent_hashes=map(lambda x: x.hash, downloading_public_torrents),
    )

    # Set remove upload speed limit for seeding public torrents
    seeding_public_torrents = client.torrents_info(
        category="Public", status_filter="seeding"
    )
    print(f"Seeding public torrents: {len(seeding_public_torrents)}")
    client.torrents_set_upload_limit(
        limit=-1, torrent_hashes=map(lambda x: x.hash, seeding_public_torrents)
    )

    # Remove finished public torrents
    completed_public_torrents = client.torrents_info(
        category="Public", status_filter="paused"
    )
    completed_public_torrents = list(
        filter(lambda x: x.state == "pausedUP", completed_public_torrents)
    )
    print(f"Completed public torrents: {len(completed_public_torrents)}")
    client.torrents_delete(
        delete_files=True,
        torrent_hashes=map(lambda x: x.hash, completed_public_torrents),
    )

    # Set private torrents higher priority
    private_torrents = client.torrents_info(category="Private")
    print(f"Private torrents: {len(private_torrents)}")
    client.torrents_top_priority(map(lambda x: x.hash, private_torrents))

    client.auth_log_out()


if __name__ == "__main__":
    main()
