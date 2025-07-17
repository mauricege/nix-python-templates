# Python on NixOS without losing your mind

A copier template to bootstrap python environments on NixOS. Borrows liberally from [Inception](https://github.com/DataChefHQ/inception).

So far, it provides two approaches:

1. [devenv.sh](https://devenv.sh) supporting uv and pip
2. A buildFHSEnv devShell supporting uv, pip, pixi and micromamba

## Usage

You can use copier:
```sh
copier copy gh:mauricege/nix-python-templates target-directory --trust
```
Or the wrapper provided by the flake:
```sh
nix run github:mauricege/nix-python-templates -- init target-directory
```
The wrapper will check your target directory for existing python packaging files, such as `uv.lock`, `environment.yml` or `pixi.lock`, to automatically set sane default for some questions. It wraps copier's `copy` (`init`) and `update`.

You can also install the wrapper to your system via nix:
```sh
nix profile install github:mauricege/nix-python-templates#python-env
python-env init target-directory
```
