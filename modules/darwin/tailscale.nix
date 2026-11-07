{
  flake.darwinModules.tailscale =
    { pkgs, ... }:
    let
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";

      # macOS reports no network path change after wake, so Tailscale keeps
      # its pre-sleep DERP and UDP sockets and waits ~30s for them to time out
      # before peers become reachable. Rebinding and dropping DERP right away
      # brings direct paths back in about a second.
      onWake = pkgs.writeShellScript "tailscale-on-wake" ''
        for _ in $(seq 20); do
          /sbin/route -n get default >/dev/null 2>&1 && break
          sleep 0.5
        done
        ${tailscale} debug rebind
        ${tailscale} debug break-derp-conns
      '';
    in
    {
      homebrew.casks = [ "tailscale" ];

      launchd.user.agents.tailscale-wake.serviceConfig = {
        ProgramArguments = [
          "${pkgs.sleepwatcher}/bin/sleepwatcher"
          "-w"
          "${onWake}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
}
