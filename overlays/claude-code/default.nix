{ channels, ... }:

final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "1.0.71";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-ZJUvscbEaWHILL77R5/sPdNcxCLc2BL9P6tR+S7QnHg=";
    };
  });
}
