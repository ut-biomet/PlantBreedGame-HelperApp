{
  lib,
  pkgs,
  ...
}: let
  R_packages = with pkgs.rPackages; [
    shiny
    shinydashboard
    shinycssloaders
    shinyjs
    DT
    plotly
    RAINBOWR
    ggplot2
    dendextend
    lme4
    glmnet
  ];

  R_with_packages = pkgs.rWrapper.override {
    packages = R_packages;
  };
in
  pkgs.stdenv.mkDerivation (finalAttrs: rec {
    pname = "PlantBreedGame-HelperApp";
    version = "v1.0";

    src = pkgs.lib.sources.cleanSource ../.;

    # To skip the Makefile `make deps`
    dontBuild = true;
    doCheck = false;

    propagatedBuildInputs = [
      R_with_packages
      pkgs.zip
    ];

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.sass
    ];

    buildPhase = ''
    '';

    checkPhase = ''
    '';

    installPhase = ''
      runHook preInstall

      mkdir $out
      mkdir $out/app
      cp ./ui.R $out/app/.
      cp ./global.R $out/app/.
      cp ./server.R $out/app/.
      cp -r ./src $out/app/src
      mkdir $out/app/www
      sass ./www/appStyle.scss $out/app/www/appStyle.css

      mkdir $out/bin
      substituteInPlace ./plantBreedGameHelperApp.sh --replace "app_dir=\".\"" "app_dir=$out/app"
      # in future the followin should be used:
      # substituteInPlace ./plantBreedGameHelperApp.sh --replace-fail "app_dir=\".\"" "app_dir=$out/app"

      cp ./plantBreedGameHelperApp.sh $out/bin/plantBreedGameHelperApp
      wrapProgram $out/bin/plantBreedGameHelperApp \
        --set PATH ${lib.makeBinPath (propagatedBuildInputs ++ [pkgs.coreutils])} \
        --set R_LIBS_USER "\"\""

      runHook postInstall
    '';
  })
