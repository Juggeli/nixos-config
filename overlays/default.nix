{
  nixpkgs.overlays = [
    (self: super: {
      mpv = super.mpv-with-scripts.override {
        scripts = [ self.mpvScripts.autoload ];
      };
    })
  ];
}