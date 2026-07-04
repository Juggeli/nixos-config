{
  flake.homeModules.comfyui =
    { inputs, pkgs, ... }:
    let
      comfyuiPkg = inputs.comfyui-nix.packages.${pkgs.system}.cuda;
      comfyuiWrapper = pkgs.writeShellScriptBin "comfyui" ''
        exec ${comfyuiPkg}/bin/comfyui --enable-cors-header --enable-manager --lowvram "$@"
      '';
    in
    {
      home-manager.users.juggeli.home.packages = [ comfyuiWrapper ];

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".config/comfy-ui"
        ];
      };
    };
}
