# The one true way to manage NixOS configurations

Hypotheses:
1. `nixos-rebuild` is *wrong* and shouldn't exist.

   Just immediately do the two things required for switching to a configuration.

2. `/etc/configuration.nix` is arbitrary and *wrong* and shouldn't exist either.

   Keep your configurations wherever you want.

It's all right there in [`default.nix`](./default.nix).
