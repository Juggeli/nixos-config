{
  flake.nixosModules.unsloth-studio =
    { pkgs, ... }:
    let
      # Unsloth Studio has no nixpkgs package; upstream distributes it as an
      # installer that bootstraps uv, a managed CPython and prebuilt CUDA
      # binaries into ~/.unsloth/studio. Those prebuilt binaries run via
      # nix-ld. Launch the web UI with `unsloth studio`.
      unsloth = pkgs.writeShellScriptBin "unsloth" ''
        # The uv-managed CPython only probes FHS certificate paths, which fail
        # on NixOS without an explicit bundle.
        export SSL_CERT_FILE="''${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
        # Setup preflights prebuilt binaries (llama.cpp, whisper.cpp) without
        # going through nix-ld, so their libraries must be resolvable via
        # LD_LIBRARY_PATH; the driver path supplies libcuda for torch.
        export LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        studio_bin="$HOME/.unsloth/studio/unsloth_studio/bin/unsloth"
        if [ ! -x "$studio_bin" ]; then
          echo "Unsloth Studio not installed, running upstream installer..." >&2
          ${pkgs.curl}/bin/curl -fsSL https://unsloth.ai/install.sh | UNSLOTH_SKIP_AUTOSTART=1 sh
        fi
        exec "$studio_bin" "$@"
      '';
    in
    {
      environment.systemPackages = [ unsloth ];

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".unsloth"
          ".cache/huggingface"
        ];
      };
    };
}
