let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9 juggeli@gmail.com";
  key2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKiEGRIqO6CX4uzbHi2Qzja8gX+oxm93AOm8Q62VreSc root@haruka";
in
{
  "borg-passkey.age".publicKeys = [ key key2 ];
}

