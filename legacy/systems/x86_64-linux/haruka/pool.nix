{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    hdparm
  ];

  powerManagement.powerUpCommands = with pkgs; ''
    for dev in /dev/sd[a-z]; do
      if [ -b "$dev" ]; then
        ${hdparm}/bin/hdparm -S 242 -B 127 "$dev" || true
      fi
    done
  '';
}
