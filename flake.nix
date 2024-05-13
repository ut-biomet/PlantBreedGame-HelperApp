{
  description = "Flake for a R environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        Rpkgs = pkgs;
        # # for specific R version:
        # Rpkgs =
        #   (import (pkgs.fetchFromGitHub {
        #       # Update to get other R version
        #       name = "nixpkgs-R-4.3.1";
        #       url = "https://github.com/NixOS/nixpkgs/";
        #       ref = "refs/heads/nixpkgs-unstable";
        #       rev = "976fa3369d722e76f37c77493d99829540d43845";
        #     })
        #     {inherit system;})
        #   .pkgs;
        R-packages = with Rpkgs.rPackages; [
          # list necessary R packages here
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

          /*
          developement packages
          */
          testthat
          languageserver
          styler
        ];
      in rec {
        packages.plantBreedGameHelperApp = pkgs.callPackage ./nix_Package/default.nix {
          inherit pkgs;
        };
        packages.default = packages.plantBreedGameHelperApp;

        devShells.default = pkgs.mkShell {
          LOCALE_ARCHIVE =
            if "${system}" == "x86_64-linux"
            then "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive"
            else "";
          LANG = "en_US.UTF-8";
          LC_ALL = "en_US.UTF-8";
          R_LIBS_USER = "''"; # to not use users' installed R packages
          R_PROFILE_USER = "''"; # to disable`.Rprofile` files (eg. when the project already use `renv`)
          R_ZIPCMD = "${pkgs.zip}/bin/zip";
          nativeBuildInputs = [pkgs.bashInteractive];
          buildInputs = [
            (Rpkgs.rWrapper.override {packages = R-packages;})
            (Rpkgs.rstudioWrapper.override {packages = R-packages;})
            pkgs.sass
          ];
        };

        apps = {
          # example of "apps" that could be run with `nix run .\#<name> -- --args`
          default = let
            runApp = pkgs.writeShellApplication {
              name = "runApp";
              text = ''
                sass www/appStyle.scss www/appStyle.css
                # Rscript --vanilla -e "shiny::runApp()"
                ./plantBreedGameHelperApp.sh "$@"
              '';
            };
          in {
            type = "app";
            program = "${runApp}/bin/runApp";
          };
        };
      }
    );
}
