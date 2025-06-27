{
  lib,
  python3,
  ffmpeg,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "process-anime";
  version = "1.0.0";

  src = ../../tools/process-anime;

  buildInputs = [
    (python3.withPackages (ps: with ps; [
      ffmpeg-python
    ]))
    ffmpeg
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp process_mkv.py $out/bin/process-anime
    chmod +x $out/bin/process-anime
    
    # Patch the shebang to use the correct Python interpreter
    substituteInPlace $out/bin/process-anime \
      --replace "#!/usr/bin/env python3" "#!${python3.withPackages (ps: with ps; [ffmpeg-python])}/bin/python3"
  '';

  meta = with lib; {
    description = "Process MKV files to keep only Japanese audio in OPUS format";
    homepage = "https://github.com/jakehamilton/dotfiles";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}