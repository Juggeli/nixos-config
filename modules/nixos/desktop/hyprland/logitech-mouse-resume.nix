{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.hyprland.logitech-mouse-resume;
in
{
  options.plusultra.desktop.hyprland.logitech-mouse-resume = with types; {
    enable = mkBoolOpt false "Whether to enable Logitech mouse driver reload after sleep.";
  };

  config = mkIf cfg.enable {
    systemd.services.logitech-mouse-resume = {
      description = "Reload Logitech mouse drivers after resume from sleep";
      after = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "logitech-mouse-resume" ''
          #!/usr/bin/env bash

          # Wait for system to stabilize after resume
          sleep 3

          # Find Logitech unifying receiver or mouse devices
          for device in /sys/bus/usb/devices/*; do
            if [[ -f "$device/idVendor" ]] && [[ -f "$device/idProduct" ]]; then
              vendor=$(cat "$device/idVendor")
              product=$(cat "$device/idProduct")
              
              # Check for Logitech devices (vendor ID 046d)
              # Common product IDs: c52b (unifying receiver), c534 (newer receiver), etc.
              if [[ "$vendor" == "046d" ]]; then
                device_name=$(basename "$device")
                echo "Found Logitech device: $device_name (vendor=$vendor, product=$product)"
                
                # Unbind and rebind the specific device
                if [[ -f "/sys/bus/usb/drivers/usb/unbind" ]] && [[ -f "/sys/bus/usb/drivers/usb/bind" ]]; then
                  echo "$device_name" > /sys/bus/usb/drivers/usb/unbind
                  sleep 1
                  echo "$device_name" > /sys/bus/usb/drivers/usb/bind
                  echo "Reset Logitech device: $device_name"
                fi
              fi
            fi
          done
        '';
      };
    };
  };
}
