{
  flake.nixosModules.tools-misc =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        fzf
        killall
        unzip
        file
        jq
        wget
        eza
        fd
        tldr
        pciutils
        grc
        smartmontools
        iotop
        htop
        list-iommu
      ];
    };
}
