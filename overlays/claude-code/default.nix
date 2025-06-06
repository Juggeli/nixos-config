{ channels, ... }:

final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "1.0.16";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-WK6EnwciMGh5vo6EB35zbEjSS3ahYeY5lwEUk2a6f9o=";
    };
  });
}
