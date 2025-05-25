let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO";
  system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiEGRIqO6CX4uzbHi2Qzja8gX+oxm93AOm8Q62VreSc";
  keys = [
    user
    user2
    system
  ];
in
{
  "borg-passkey.age".publicKeys = keys;
  "cloudflared.age".publicKeys = keys;
  "syncthing-key.age".publicKeys = keys;
  "syncthing-cert.age".publicKeys = keys;
  "borg-healthcheck.age".publicKeys = keys;
  "storagebox-url.age".publicKeys = keys;
  "ntfy-topic.age".publicKeys = keys;
  "zfs.age".publicKeys = keys;
  "cloudflare-dns.age".publicKeys = keys;
  "homepage-env.age".publicKeys = keys;
}
