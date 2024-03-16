{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "ab-av1";
  version = "0.7.14";

  src = fetchFromGitHub {
    owner = "alexheretic";
    repo = "ab-av1";
    rev = "v${version}";
    sha256 = "sha256-cDabGXNzusVnp4exINqUitEL1HnzSgpcRtYXU5pSRhY=";
  };

  cargoSha256 = "sha256-sW/673orvK+mIUqTijpNh4YGd9ZrgSveGT6F1O5OYfI=";

  meta = with lib; {
    description = "AV1 re-encoding using ffmpeg, svt-av1 & vmaf.";
    homepage = "https://github.com/alexheretic/ab-av1";
    license = licenses.mit;
    maintainers = [ ];
  };
}
