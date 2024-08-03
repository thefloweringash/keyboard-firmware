{ stdenv, lib, buildEnv, runCommand, makeWrapper, avrgcc, avrlibc, avrbinutils,
  bundlerEnv, ruby }:

lib.makeOverridable ({ name, hardwareLibrary, hardwareVariant, hasStorage ? true }:

let
  avrgcc-wrapper = runCommand "avrgcc-wrapper" {
    buildInputs = [ makeWrapper ];
  } ''
    mkdir -p $out/bin
    ln -s ${avrgcc}/bin/* $out/bin
  '';

  firmware = stdenv.mkDerivation {
    inherit name;
    src = lib.cleanSource ./..;

    HARDWARE_VARIANT = hardwareVariant;
    HAS_STORAGE      = hasStorage;
    HARDWARE_LIBRARY = hardwareLibrary;

    buildInputs = [ avrgcc-wrapper avrbinutils ];

    buildPhase = ''
      make -f Makefile.$HARDWARE_LIBRARY $makeFlags
    '';

    installPhase = ''
      mkdir $out
      cp *.{hex,elf} $out/
    '';

    dontFixup = true;
  };

  extractDefaultMappingEnv = bundlerEnv {
    name = "extra-default-mapping";
    inherit ruby;
    gemdir = ../qtclient/extract-default-mapping;
  };

  mapping = firmware.overrideAttrs (attrs: {
    name = "${attrs.name}-default-mapping";
    buildInputs = attrs.buildInputs ++ [ extractDefaultMappingEnv.wrappedRuby ];
    buildPhase = ''
      make -f Makefile.$HARDWARE_LIBRARY obj/hardware.o
      ruby ./qtclient/extract-default-mapping/extract-default-mapping.rb ${name}_default_mapping > extracted_mapping.c
    '';
    installPhase = ''
      cp extracted_mapping.c $out
    '';
  });

in

lib.extendDerivation true { inherit mapping; } firmware

)
