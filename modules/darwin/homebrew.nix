{
  flake.darwinModules.homebrew =
    let
      taps = [ "lutzifer/tap" ];
      # third-party taps Homebrew 6 refuses to load unless trusted;
      # nikitabobko/tap backs the aerospace cask (see aerospace.nix)
      trustedTaps = taps ++ [ "nikitabobko/tap" ];
      trustJson = builtins.toJSON { trustedtaps = trustedTaps; };
    in
    {
      homebrew = {
        enable = true;
        brews = [ "lutzifer/homebrew-tap/keyboardSwitcher" ];
        inherit taps;
        casks = [
          "cmux"
          "obsidian"
          "zen"
          "1password"
          "discord"
          "balenaetcher"
          "todoist-app"
          "bettertouchtool"
          "orcaslicer"
          "superslicer"
        ];
      };

      system.activationScripts.preActivation.text = ''
        install -d -o juggeli /Users/juggeli/.homebrew
        printf '%s' '${trustJson}' > /Users/juggeli/.homebrew/trust.json
        chown juggeli /Users/juggeli/.homebrew/trust.json
      '';

      home-manager.users.juggeli.home.sessionPath = [
        "/opt/homebrew/bin"
      ];
    };
}
