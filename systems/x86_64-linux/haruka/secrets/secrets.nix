let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9 juggeli@gmail.com";
in
{
  "borg-passkey.age".publicKeys = [ key ];
}

