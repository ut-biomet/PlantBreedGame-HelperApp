{
  pkgs,
  nix2containerPkgs,
}: {
  builder = {
    imageName ? null,
    plantBreedGameHelperApp ? null,
  }: let
  in
    nix2containerPkgs.nix2container.buildImage {
      name = imageName;
      tag = "latest";
      copyToRoot = [
        (pkgs.buildEnv {
          name = "root";
          paths = [
            plantBreedGameHelperApp
            pkgs.dockerTools.fakeNss
            pkgs.dockerTools.binSh
          ];
          pathsToLink = ["/bin" "/var" "/run" "/tmp"];
        })
      ];

      config = {
        Cmd = ["${plantBreedGameHelperApp}/bin/plantBreedGameHelperApp" "-p" "3838" "-H" "0.0.0.0"];
        Expose = 3838;
      };
    };
}
