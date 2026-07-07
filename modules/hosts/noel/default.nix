{ self, ... }:
{
  flake.nixosConfigurations.noel = self.lib.mkNixos {
    hostName = "noel";
    modules =
      (with self.nixosModules; [
        base
        networking
        impermanence
        tmpfs
        hardware-audio
        hardware-logitech
        services-printing
        theming
        hyprland
        hyprlock
        hypridle
        wlsunset
        logitech-mouse-resume
        desktop-gtk
        desktop-qt
        desktop-mako
        desktop-rofi
        desktop-electron
        onepassword
        avahi
        flatpak
        syncthing
        earlyoom
        gaming
        kdeconnect
        dev-rust
        home-impermanence

        noel-system
        noel-disk
        noel-hardware
        noel-autologin
        noel-borgmatic
      ])
      ++ (with self.homeModules; [
        desktop
        process-anime
        ffmpeg
        imv
        sshfs
        ab-av1
        nushell
        sorter
        discord
        firefox
        chrome
        via
        pdf
        crypto
        hydrus
        anytype
        vscode
        comfyui
        lmstudio
        waybar
      ]);
  };
}
