
dockerImage:
	nix run .\#images.x86_64-linux.plantBreedGameHelperApp.copyToDockerDaemon

pushImage:
	nix run .\#images.x86_64-linux.plantBreedGameHelperApp.copyToRegistry
