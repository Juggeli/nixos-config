{
  flake.nixosModules.haruka-forgejo =
    { config, pkgs, ... }:
    {
      services.forgejo = {
        enable = true;
        # Under /mnt/appdata so borgmatic's existing source directory covers
        # the repositories and sqlite database without a separate dump step.
        stateDir = "/mnt/appdata/forgejo";
        settings = {
          server = {
            # MagicDNS resolves the bare hostname on the tailnet, matching how
            # browsers and agents actually reach the instance.
            DOMAIN = "haruka";
            ROOT_URL = "http://haruka:3300/";
            HTTP_PORT = 3300;
            # Builtin SSH server rather than the host sshd, so git-over-ssh
            # keys live in forgejo's own state instead of the host account.
            # 2223 because the host sshd already listens on 2222.
            START_SSH_SERVER = true;
            SSH_PORT = 2223;
          };
          # Single-user instance; accounts are created by the admin CLI.
          service.DISABLE_REGISTRATION = true;
        };
      };

      # Same pattern as the container web UIs: bound wide, admitted only from
      # the tailnet because enp1s0 also carries globally routable IPv6.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        2223
        3300
      ];

      # The module does not put the CLI on PATH, and it must run as the
      # forgejo user with the service's HOME/work dir to find app.ini and to
      # keep state file ownership intact; wrap all of that for admin one-offs.
      environment.systemPackages =
        let
          cfg = config.services.forgejo;
        in
        [
          (pkgs.writeShellScriptBin "forgejo-cli" ''
            exec doas -u ${cfg.user} env HOME=${cfg.stateDir} FORGEJO_WORK_DIR=${cfg.stateDir} ${cfg.package}/bin/forgejo "$@"
          '')
        ];
    };
}
