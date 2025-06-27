{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  pname = "gemini-cli";
  version = "2025-06-27";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "5fd6664c4b1c4a1ca84119ea709e5dac2a9fce70";
    hash = "sha256-po0jfhJaEI7XszXvGwpGXpCFquJd6br1i92ZbcL4jD4=";
  };

  npmDepsHash = "sha256-qimhi2S8fnUbIq2MPU1tlvj5k9ZChY7kzxLrYqy9FXI=";

  postPatch = ''
    mkdir -p packages/cli/src/generated
    echo "export const GIT_COMMIT_INFO = {};" > packages/cli/src/generated/git-commit.js
    echo "export const GIT_COMMIT_INFO: any;" > packages/cli/src/generated/git-commit.d.ts
  '';

  buildPhase = ''
    runHook preBuild
    npm run build:packages
    npm run bundle
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r bundle/* $out/bin
    ln -s $out/bin/gemini.js $out/bin/gemini
    runHook postInstall
  '';

  meta = with lib; {
    description = "A CLI for Gemini";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
