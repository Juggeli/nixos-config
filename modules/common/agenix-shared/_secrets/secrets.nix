let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO";
  jukkas_mbp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbJeg8M8Pmbab+/X5on+hFEJlLW0/f4vX8nNtDNAcox";
  noel = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRcPjReo8vFNgTRYYaJ6Q+wYdOxF414AFJuF3utHyd2";
  haruka = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiEGRIqO6CX4uzbHi2Qzja8gX+oxm93AOm8Q62VreSc";
  keys = [
    user1
    user2
    jukkas_mbp
    noel
    haruka
  ];
in
{
  "zai-api-key.age".publicKeys = keys;
  "brave-api-key.age".publicKeys = keys;
  "exa-api-key.age".publicKeys = keys;
  "openrouter-api-key.age".publicKeys = keys;
  "ollama-api-key.age".publicKeys = keys;
}
