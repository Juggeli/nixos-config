# qBittorrent Manager

A NixOS service for automated qBittorrent management, including categorization, share limits, and cleanup.

## Features

- **Automatic categorization**: Uses qBittorrent's built-in private torrent flag to categorize torrents as "Public" or "Private"
- **Share ratio management**: Sets configurable share ratio limits for public torrents
- **Upload speed limits**: Applies upload limits to downloading public torrents, removes limits when seeding
- **Cleanup**: Automatically removes completed public torrents that have reached their share ratio
- **Arr app cleanup**: Removes completed torrents from post-import categories (e.g., sonarr-done, radarr-done)
- **Priority management**: Sets higher priority for private torrents
- **Dry-run support**: Preview changes without making modifications
- **Secure credential management**: Uses agenix for encrypted credential storage

## NixOS Module Usage

### 1. Enable the Service

Add to your NixOS configuration:

```nix
plusultra.services.qbittorrent-manager = {
  enable = true;
  connection = {
    host = "your-qbittorrent-host";
    port = 8080;
    credentialsFile = config.age.secrets.qbittorrent-credentials.path;
  };
  limits = {
    publicRatio = 2.0;
    uploadLimitDownloading = 200000; # bytes/second
  };
  cleanup = {
    arrCategories = [ "sonarr-done" "sonarr-anime-done" "radarr-done" "radarr-anime-done" ];
  };
  schedule = "0 */2 * * *"; # Every 2 hours
};
```

### 2. Create Agenix Secret

First, create the credentials file with the format expected by the service:

```bash
# Create credentials file
echo 'QBIT_USERNAME=your-username' > qbit-creds.env
echo 'QBIT_PASSWORD=your-password' >> qbit-creds.env

# Encrypt with agenix
agenix -e systems/x86_64-linux/your-host/secrets/qbittorrent-credentials.age
# Paste the contents of qbit-creds.env, save and exit

# Clean up
rm qbit-creds.env
```

### 3. Add to secrets.nix

Add the secret to your host's `secrets/secrets.nix`:

```nix
{
  # ... other secrets
  "qbittorrent-credentials.age".publicKeys = keys;
}
```

### 4. Configure Arr Applications

For safe cleanup, configure your arr applications to use post-import categories:

**Sonarr/Radarr Settings:**
- Go to Settings → Download Clients → qBittorrent
- Set **Category** to `sonarr` (or `radarr`, `sonarr-anime`, etc.)  
- Set **Post-Import Category** to `sonarr-done` (or `radarr-done`, `sonarr-anime-done`, etc.)

This ensures torrents are only cleaned up **after** successful import, preventing data loss.

## Configuration Options

### Connection Settings
- `host`: qBittorrent host (default: "localhost")
- `port`: qBittorrent port (default: 8080)
- `credentialsFile`: Path to agenix-encrypted credentials

### Limits
- `publicRatio`: Share ratio limit for public torrents (default: 2.0)
- `uploadLimitDownloading`: Upload speed limit for downloading public torrents in bytes/second (default: 200000)

### Cleanup
- `arrCategories`: List of post-import categories to clean completed torrents from (default: `[ "sonarr-done" "sonarr-anime-done" "radarr-done" "radarr-anime-done" ]`)

### Scheduling
- `schedule`: systemd timer OnCalendar format (default: "hourly")

### Security
- `user`: System user to run as (default: "qbit-manager")
- `group`: System group to run as (default: "qbit-manager")

## Manual Usage

The tool can also be run manually:

```bash
# Run with default settings
qbit-manager

# Use custom config file
qbit-manager -c config.json

# Dry run (preview changes)
qbit-manager --dry-run

# Verbose logging
qbit-manager -v

# Environment variables
export QBIT_HOST=localhost
export QBIT_PORT=8080
export QBIT_USERNAME=admin
export QBIT_PASSWORD=password
export QBIT_ARR_CATEGORIES=sonarr-done,sonarr-anime-done,radarr-done,radarr-anime-done
qbit-manager
```

## Configuration File Format

JSON configuration file:

```json
{
  "host": "localhost",
  "port": 8080,
  "username": "admin", 
  "password": "password",
  "public_ratio_limit": 2.0,
  "upload_limit_downloading": 200000,
  "arr_categories": ["sonarr-done", "sonarr-anime-done", "radarr-done", "radarr-anime-done"]
}
```

## How It Works

1. **Categorization**: Creates "Public" and "Private" categories if they don't exist
2. **Detection**: Uses qBittorrent's built-in `torrent.private` flag to detect private torrents
3. **Share Limits**: Sets ratio limits on public torrents to prevent excessive seeding
4. **Speed Management**: Limits upload speed during download, removes limits when seeding
5. **Cleanup**: Removes completed public torrents that have met their share ratio
6. **Prioritization**: Ensures private torrents get priority over public ones

## Systemd Integration

The NixOS module creates:
- A oneshot systemd service with security hardening
- A systemd timer for scheduled execution
- Proper user/group isolation
- Agenix secret mounting

## Security

The service runs with extensive security hardening:
- Dedicated user/group
- No new privileges
- Private temporary directories
- Protected system directories
- Restricted system calls
- No network access to unauthorized endpoints