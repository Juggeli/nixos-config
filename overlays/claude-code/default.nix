{ channels, ... }:

final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "1.0.67";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-NZgv0nGsq+RuPTJcX0GsE1NWs/PFge2A0ek3BL1fJeY=";
    };
  });
}
