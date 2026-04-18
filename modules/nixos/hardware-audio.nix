{
  flake.nixosModules.hardware-audio =
    { pkgs, ... }:
    {
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      environment.systemPackages = with pkgs; [
        pulsemixer
        pavucontrol
        qjackctl
        easyeffects
      ];

      users.users.juggeli.extraGroups = [ "audio" ];
    };
}
