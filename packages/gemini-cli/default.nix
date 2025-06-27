{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  pname = "gemini-cli";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "3a369ddec3b226dea9d1a9dcc3bae048310edffd";
    hash = "sha256-ygBh8n+8bWmqTgvLnMFp2H7txstGg249+vpXyoKg5E8=";
  };

  npmDepsHash = "sha256-2zyMrVykKtN+1ePQko9MVhm79p7Xbo9q0+r/P22buQA=";

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