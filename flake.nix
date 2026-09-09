{
  description = "Dell Inspiron 14 Plus 7441 (Snapdragon X Elite X1E80100) - flakes, unstable, latest kernel, vendored X1E bits";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    singularity-flake.url = "github:mateoalfaro/singularity-flake";
    llms.url = "github:numtide/llm-agents.nix";
  };

  outputs = { self, nixpkgs, llms, singularity-flake, ... }@inputs: {
    nixosConfigurations.dell7441 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        singularity-flake.nixosModules.default
      ];
    };
  };
}
