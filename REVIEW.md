A basic overview of the what should be reviewed.

### Prerequisites
- Nixops deployment needs libvirtd (flake's checks should the same)

### Notes
- Verify command line doesn't unexpectedly crash out with an unidentifiable or unrecognizable error
- slapd is openldap in NixOS

### Test Script

```bash
#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nixFlakes

# Run flake checks
nix --experimental-features "flakes nix-command" flake check github:ngi-nix/yunohost

# Create nixops virtual machine
nixops create -d yunohost --flake github:ngi-nix/yunohost/nixops
# Deploy vm
nixops deploy -d yunohost
# ssh
nixops ssh -d yunohost yunohost
```
