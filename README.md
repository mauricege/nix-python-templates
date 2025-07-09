# Python on NixOS without losing your mind

A copier template to bootstrap python environments on NixOS. Borrows liberally from [Inception](https://github.com/DataChefHQ/inception).

So far, it provides two approaches:

1. [devenv.sh](https://devenv.sh) supporting uv and pip
2. A buildFHSEnv devShell, supporting uv, pip, pixi and micromamba