{ lib, python3Packages }:

python3Packages.buildPythonPackage {
  pname = "qbit-manager";
  version = "0.1";

  src = ./.;

  nativeBuildInputs = [
    python3Packages.setuptools
  ];

  propagatedBuildInputs = [
    python3Packages.qbittorrent-api
  ];

  meta = with lib; {
    homepage = "";
    description = "Python script to manage qbittorrent";
    license = lib.licenses.gpl3;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
