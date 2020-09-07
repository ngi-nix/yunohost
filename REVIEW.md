A basic overview of the what should be reviewed.

### Prerequisites
- VM environment needs Qemu to be installed

### Notes
- Verify YunoHost is packaged
- Verify command line doesn't unexpectedly crash out with an unidentifiable or unrecognizable error (i.e. a segfault)

### Test Script

```bash
#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nixFlakes

# Run flake checks
nix --experimental-features "flakes nix-command" flake check github:ngi-nix/yunohost

# VM Environment, to play around with the command
nix build -L github:ngi-nix/yunohost#nixosConfigurations.vm.config.system.build.vm
result/bin/run-qemu_virtual-vm
```
