{
  flake.nixosModules.home-ffmpeg =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = with pkgs; [
        (ffmpeg-headless.override { withVmaf = true; })
        mkvtoolnix
        makemkv
      ];
    };
}
