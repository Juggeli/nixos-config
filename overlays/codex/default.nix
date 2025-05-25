{ channels, ... }:

final: prev: {
  codex = prev.stdenv.mkDerivation rec {
    pname = "codex";
    version = "0.1.2505172129";

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}.tgz";
      hash = "sha256-hUIT4t56xkomESF6erXH40nTX+ChAGLqaJeWuoQwn7s=";
    };

    buildInputs = [ prev.nodejs_22 ];

    installPhase = ''
      runHook preInstall
      
      mkdir -p $out/lib/node_modules/@openai/codex
      cp -r * $out/lib/node_modules/@openai/codex/
      
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/@openai/codex/bin/codex.js $out/bin/codex
      chmod +x $out/bin/codex
      
      runHook postInstall
    '';
  };
}

