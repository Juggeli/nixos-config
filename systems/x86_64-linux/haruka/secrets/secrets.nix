let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO";
  system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiEGRIqO6CX4uzbHi2Qzja8gX+oxm93AOm8Q62VreSc";
in
{
  "borg-passkey.age".publicKeys = [
    user
    user2
    system
  ];
  "cloudflared.age".publicKeys = [
    user
    user2
    system
  ];
  "syncthing-key.age".publicKeys = [
    user
    user2
    system
  ];
  "syncthing-cert.age".publicKeys = [
    user
    user2
    system
  ];
  "borg-healthcheck.age".publicKeys = [
    user
    user2
    system
  ];
  "storagebox-url.age".publicKeys = [
    user
    user2
    system
  ];
  "ntfy-topic.age".publicKeys = [
    user
    user2
    system
  ];
  "zfs.age".publicKeys = [
    user
    user2
    system
  ];
  "cloudflare-dns.age".publicKeys = [
    user
    user2
    system
  ];
  "homepage-env.age".publicKeys = [
    user
    user2
    system
  ];
}
