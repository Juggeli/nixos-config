{ lib, stdenv, pkgs, ... }:

stdenv.mkDerivation {
  pname = "prometheus-smartcetl";
  version = "2.2.0";

  src = pkgs.fetchFromGitHub {
    owner = "matusnovak";
    repo = "prometheus-smartctl";
    rev = "v2.2.0";
    sha256 = "sha256-GwNSrKNbwuPc65BN7rXLg/lUNqLgthu9SZPJphXAByg=";
  };

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  buildInputs = [
    (pkgs.python3.withPackages (p: with p; [
      prometheus_client
    ]))
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/smartprom.py $out/bin/smartprom
    chmod +x $out/bin/smartprom
  '';

  postFixup = ''
    wrapProgram $out/bin/smartprom \
      --set PATH ${lib.makeBinPath [
        pkgs.smartmontools
      ]}
  '';

  meta = {
    homepage = "https://github.com/matusnovak/prometheus-smartctl";
    description = "HDD S.M.A.R.T exporter for Prometheus written in Python";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}

