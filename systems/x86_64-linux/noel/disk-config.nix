let
  rawdisk1 = "/dev/nvme1n1"; # CHANGE
in
{
  disko.devices = {
    disk = {
      ${rawdisk1} = {
        device = "${rawdisk1}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "EFI";
              name = "ESP";
              size = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              label = "encrypted";
              size = "100%";
              content = {
                type = "luks";
                name = "pool0_0";
                extraOpenArgs = [ "--allow-discards" ];
                passwordFile = "/tmp/secret.key"; # Interactive
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/root-blank" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist-home" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist-home/active" = {
                      mountpoint = "/persist-home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist-home/snapshots" = {
                      mountpoint = "/persist-home/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist/active" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist/snapshots" = {
                      mountpoint = "/persist/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/var_log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "64G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
