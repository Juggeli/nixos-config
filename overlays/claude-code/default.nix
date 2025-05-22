{ channels, ... }:

final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "1.0.0";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-DwZJDl+Yt6ULpumSnwktWCJZPxFgdsDkRHAt+6C/BcM=";
    };
  });
}

