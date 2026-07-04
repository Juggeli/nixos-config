let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO";
  system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRcPjReo8vFNgTRYYaJ6Q+wYdOxF414AFJuF3utHyd2";
  keys = [
    user
    system
  ];
in
{
  "borg-passkey.age".publicKeys = keys;
  "smb.age".publicKeys = keys;
  "tailscale.age".publicKeys = keys;
  "syncthing-key.age".publicKeys = keys;
  "syncthing-cert.age".publicKeys = keys;
  "storagebox-url.age".publicKeys = keys;
  "storagebox-hydrus-url.age".publicKeys = keys;
  "borg-healthcheck.age".publicKeys = keys;
  "borg-hydrus-healthcheck.age".publicKeys = keys;
  "borg-hydrus-offsite-healthcheck.age".publicKeys = keys;
}
