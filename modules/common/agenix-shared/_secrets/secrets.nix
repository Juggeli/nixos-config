let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO";
  monday_chan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbJeg8M8Pmbab+/X5on+hFEJlLW0/f4vX8nNtDNAcox";
  kuro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9WCTLyOQMqPuWuBrqHDO+MbTHRrdeGcXAkjl1pj0Z3";
  noel = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRcPjReo8vFNgTRYYaJ6Q+wYdOxF414AFJuF3utHyd2";
  haruka = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiEGRIqO6CX4uzbHi2Qzja8gX+oxm93AOm8Q62VreSc";
  keys = [
    user1
    user2
    monday_chan
    kuro
    noel
    haruka
  ];
in
{
  "agent-env.age".publicKeys = keys;
  "forgejo-fj-keys.age".publicKeys = keys;
}
