{
  flake.nixosModules.dev-rust =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        rustup
        clang
        pkg-config
      ];

      home-manager.users.juggeli.home.sessionPath = [ "$HOME/.cargo/bin" ];

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".rustup"
        ];
      };
    };
}
