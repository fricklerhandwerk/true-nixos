{ system ? builtins.currentSystem
, sources ? import ./npins
, pkgs ? import sources.nixpkgs {
    config = { };
    overlays = [ ];
    inherit system;
  }
, lib ? import "${sources.nixpkgs}/lib"
,
}:
let
  switch = pkgs.writeShellApplication {
    name = "switch";
    text = ''
      machine="$1"
      shift
      # shellcheck disable=SC2086
      # shellcheck disable=SC2068
      result="$(nix-build --no-out-link ${toString ./.} -A machines.$machine $@)"
      sudo nix-env -p /nix/var/nix/profiles/system --set "$result"
      sudo "$result"/bin/switch-to-configuration switch
    '';
  };

  build = pkgs.writeShellApplication {
    name = "build";
    text = ''
      machine="$1"
      shift
      nix-build ${toString ./.} -A machines."$machine".config.system.build.toplevel "$@"
    '';
  };
in
rec {
  configs.base = { ... }:
    {
      imports = [
        # on a fresh machine, run:
        #
        #     nixos-generate-config --show-hardware-config > hardware-configuration.nix
        #
        # and uncomment:
        #
        #./hardware-configuration.nix
      ];
      users.users = {
        # don't forget to set up users
      };
      system.stateVersion = "24.11";
      nixpkgs.hostPlatform = "x86_64-linux";
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    };

  machines =
    let
      nixos-configuration = module:
        import "${sources.nixpkgs}/nixos/lib/eval-config.nix" {
          modules = [
            module
            "${sources.disko}/module.nix"
            ({ pkgs, config, ... }: {
              # add `sources` to module arguments
              _module.args = { inherit sources; };
              # disko is ships being enabled by default,
              # but it's not necessarily configured for each machine.
              disko.enableConfig = lib.mkDefault false;
              nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
            })
          ];
          # this is needed for some legacy Nixpkgs reason I don't fully understand
          system = null;
        };
    in
    lib.mapAttrs (_: config: nixos-configuration config) configs;

  shell =
    pkgs.mkShell {
      packages = [
        pkgs.npins
        build
        switch
      ];
    };
}
