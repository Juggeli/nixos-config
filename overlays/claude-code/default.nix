{ channels, ... }:

final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "1.0.61";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-K10rlFGi2KH65VE0kiBY1lU16xkMPV24/GSD6OjU3v0=";
    };
  });
}
