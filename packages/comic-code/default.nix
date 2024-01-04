{ lib, stdenv, ... }:

stdenv.mkDerivation {
  name = "comic-code";

  src = ./comic-code;

  phases = "installPhase";
  installPhase = ''
    install -m444 -Dt $out/share/fonts/opentype $src/*.otf
  '';

  meta = with lib; {
    homepage = "";
    description = "Comic code font";
    license = lib.licenses.gpl3;
    platforms = platforms.all;
    maintainers = [ ];
  };
}

