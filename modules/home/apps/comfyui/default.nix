{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.comfyui;
  comfyuiPkg = inputs.comfyui-nix.packages.${pkgs.system}.cuda;
  comfyuiWrapper = pkgs.writeShellScriptBin "comfyui" ''
    exec ${comfyuiPkg}/bin/comfyui --enable-cors-header --enable-manager --lowvram "$@"
  '';
in
{
  options.plusultra.apps.comfyui = with types; {
    enable = mkBoolOpt false "Whether or not to enable ComfyUI.";
  };

  config = mkIf cfg.enable {
    home.packages = [ comfyuiWrapper ];

    plusultra.user.impermanence.directories = [
      ".config/comfy-ui"
    ];
  };
}
