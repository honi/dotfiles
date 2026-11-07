# Home Manager configuration: the home layer, as a library for overlays.
#
# flake.lock pins nixpkgs, nixpkgs-unstable (passed to modules as pkgs-unstable,
# for the few packages that must be current) and Home Manager. An overlay's own
# flake takes this flake as an input and builds its configuration with
# lib.mkHome, so its flake.lock pins the exact base commit, and through it
# these same nixpkgs and Home Manager.
#
# Outputs:
#   lib.mkHome MODULES          a configuration: the base modules, then MODULES
#   homeConfigurations.base     the base modules only
#   packages.home-manager       the pinned home-manager command
#   checks                      builds the base configuration
#   formatter                   nixfmt-tree (nixfmt over every Nix file), for `nix fmt`
{
  description = "Home configuration: the base modules, and mkHome for overlays";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};

      mkHome =
        modules:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit pkgs-unstable; };
          modules = [ ./modules ] ++ modules;
        };

      homeConfigurations.base = mkHome [ ];
    in
    {
      lib = { inherit mkHome; };

      inherit homeConfigurations;

      packages.${system}.home-manager = home-manager.packages.${system}.default;

      checks.${system} = nixpkgs.lib.mapAttrs (_: home: home.activationPackage) homeConfigurations;

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
