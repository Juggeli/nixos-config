let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO";
  system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRcPjReo8vFNgTRYYaJ6Q+wYdOxF414AFJuF3utHyd2";
in
{
  "borg-passkey.age".publicKeys = [ user system ];
  "smb.age".publicKeys = [ user system ];
}
