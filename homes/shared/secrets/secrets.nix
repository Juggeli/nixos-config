let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPwDXLTCnNPVKSLHgbzlcgdbb6Ra+L2jZJfOJaSgom9";
  user2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO";
  keys = [
    user1
    user2
  ];
in
{
  "zai.age".publicKeys = keys;
  "minimax.age".publicKeys = keys;
}
