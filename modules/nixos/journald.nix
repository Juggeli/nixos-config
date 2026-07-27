{
  flake.nixosModules.journald = {
    # systemd caps the journal at 10% of its filesystem by default, which on a
    # 63G root works out to ~6G. That competes with the nix store for the same
    # space, and no host here needs more than a month of logs to debug from.
    services.journald.extraConfig = ''
      SystemMaxUse=1G
      MaxRetentionSec=1month
    '';
  };
}
