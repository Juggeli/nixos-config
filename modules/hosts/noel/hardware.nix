{
  flake.nixosModules.noel-hardware =
    {
      modulesPath,
      inputs,
      pkgs,
      config,
      ...
    }:
    let
      inherit (inputs) nixos-hardware;

      nvidia-smi = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";

      comfyuiUnload = pkgs.writeShellScript "comfyui-unload" ''
        ${pkgs.curl}/bin/curl -sf -m 10 -X POST \
          -H 'Content-Type: application/json' \
          -d '{"unload_models": true, "free_memory": true}' \
          http://127.0.0.1:8188/free || exit 0

        for _ in $(seq 1 30); do
          used=$(${nvidia-smi} --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null) || exit 0
          [ "$used" -lt 2048 ] && break
          sleep 1
        done
        exit 0
      '';
    in
    {
      imports = with nixos-hardware.nixosModules; [
        (modulesPath + "/installer/scan/not-detected.nix")
        common-cpu-intel
        common-pc
        common-pc-ssd
      ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        # The default kernel-suspend-notifier path (open driver >= 595) has no
        # nvidia-suspend/resume services and deadlocked in nvidia_uvm when a
        # CUDA process was alive at suspend; use the systemd services instead.
        powerManagement.kernelSuspendNotifier = false;
        open = true;
        nvidiaSettings = true;
      };

      # VRAM preservation of a loaded ComfyUI spikes system RAM and earlyoom
      # kills it; teardown then wedges in uvm_va_space_mm_shutdown, blocking
      # the kernel freezer and aborting suspend with EBUSY. Unload models via
      # the ComfyUI API instead so preservation only copies desktop VRAM.
      systemd.services.comfyui-unload = {
        description = "Unload ComfyUI models before suspend";
        wantedBy = [ "sleep.target" ];
        before = [
          "sleep.target"
          "nvidia-suspend.service"
          "nvidia-hibernate.service"
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "1min";
          ExecStart = comfyuiUnload;
        };
      };

      boot = {
        initrd.availableKernelModules = [
          "xhci_pci"
          "ahci"
          "nvme"
          "usbhid"
          "aesni_intel"
        ];

        kernelModules = [ "kvm-intel" ];
        kernelParams = [
          "mitigations=off"
        ];

        loader.grub.mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/boot";
          }
          {
            devices = [ "nodev" ];
            path = "/boot-fallback";
          }
        ];
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/E74E-4B34";
        fsType = "vfat";
        options = [ "nofail" ];
      };

      fileSystems."/boot-fallback" = {
        device = "/dev/disk/by-uuid/ACD6-8BE8";
        fsType = "vfat";
        options = [ "nofail" ];
      };

      networking = {
        interfaces.enp5s0.useDHCP = true;
        hostId = "cc5b25a0";
      };

      zramSwap.enable = true;

      hardware.enableRedistributableFirmware = true;

      hardware.cpu.intel.updateMicrocode = true;
    };
}
