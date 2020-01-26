{ stdenv, mkDerivation, lib, qmake, qtbase, libusb, pkgconfig,
 withCompiler ? false, compiler ? null,
}:

assert withCompiler -> compiler != null;

mkDerivation {
  name = "qtclient";
  src = lib.cleanSource ../qtclient;
  nativeBuildInputs = [ qmake pkgconfig ];
  buildInputs = [ libusb qtbase ];

  postPatch = ''
    substituteInPlace qtclient.pro \
      --replace "/usr/bin/"  "/bin" \
      --replace "/usr/share" "/share"
  '';

  preConfigure = lib.optionalString withCompiler ''
    patchShebangs ./integrate-compiler.sh
    env GHC=${compiler.ghc} COMPILER=${compiler} ./integrate-compiler.sh > compiler.pri
  '';

  qmakeFlags = ["CONFIG+=release"] ++ lib.optional withCompiler "USE_COMPILER=1";

  installPhase = if stdenv.isDarwin then ''
    mkdir -p $out/Applications
    mv KeyboardClient.app $out/Applications

    wrapQtApp $out/Applications/KeyboardClient.app/Contents/MacOS/KeyboardClient
  '' else ''
    make install INSTALL_ROOT=$out
  '';

  # See NixOS/patchelf#98; NixOS/nixpkgs#26209
  preFixup = ''
    rm -rf $(pwd)/../__nix_qt5__
  '';

  enableParallelBuilding = true;
}
