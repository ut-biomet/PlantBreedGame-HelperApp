{
  description = "Flake for a R environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system:
        let
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
          R-with-my-packages = Rpkgs.rWrapper.override {
            packages = with Rpkgs.rPackages; [
              # list necessary R packages here
              shiny
              shinydashboard
              shinycssloaders
              shinyjs
              DT
              plotly
              RAINBOWR
              dendextend
              lme4

              /*
              developement packages
              */
              testthat
            ];
          };
        in {

          packages = {
          };

          devShells.default =
            pkgs.mkShell {
              LOCALE_ARCHIVE = if "${system}" == "x86_64-linux" then "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive" else "";
              R_LIBS_USER = "''"; # to no use users' installed R packages
              nativeBuildInputs = [pkgs.bashInteractive];
              buildInputs = [
                R-with-my-packages
              ];
            };

          apps = {
            # example of "apps" that could be run with `nix run .\#<name> -- --args`
            runApp = let
              runApp = pkgs.writeShellApplication {
                name = "runApp";
                text = ''
                  Rscript --vanilla -e "shiny::runApp()"
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

