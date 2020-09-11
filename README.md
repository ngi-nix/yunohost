## YunoHost [Nixified]

Funded by the European Commission under the [Next Generation Internet](https://www.ngi.eu/ngi-projects/ngi-zero/) initiative

### Objective

1. Package YunoHost for Nix
2. Allow seamless integration with NixOS for a declarative and reproducible setup and management of the software

### Current State

As of 2020, September 11, this flake is __not__ in an operational state.

For future maintainers who attempt to finish up this up, note that the codebase for YunoHost is not really ideal for Nix, the paths used in it are mainly hard-coded. While that works for most of the other Linux distributions, for NixOS it would end up resulting in a fragile module that is likely to break with every release.
