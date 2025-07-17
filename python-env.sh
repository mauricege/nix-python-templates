#!/usr/bin/env bash
# set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: python-env <destination-directory>"
    exit 1
fi

TEMPLATE_DIR="gh:mauricege/nix-python-templates"
dst_path=$(realpath "$1")

# List files in the destination path, or set to empty if directory does not exist
if [ -d "$dst_path" ]; then
    files=$(ls "$dst_path")
else
    files=""
fi

echo "Checking for python package manager files in $dst_path:"
if [[ $files == *"pyproject.toml"* ]]; then
    echo "Found pyproject.toml, using uv as package manager. Could also be poetry or pixi, but we default to uv."
    pythonPackageManager="uv"
    pythonProjectFileExists=true
fi
if [[ $files == *"uv.lock"* ]]; then
    echo "Found uv.lock, using uv as package manager."
    pythonPackageManager="uv"
    pythonProjectFileExists=true
fi

if [[ $files == *"pixi.lock"* ]] || [[ $files == *"pixi.toml"* ]]; then
    echo "Found pixi.lock or pixi.toml, using pixi as package manager."
    pythonPackageManager="pixi"
    pythonProjectFileExists=true
fi

if [[ $files == *"environment.yml"* ]]; then
    echo "Found environment.yml, using micromamba as package manager."
    pythonPackageManager="micromamba"
    pythonProjectFileExists=true
fi

pythonPackageManager=''${pythonPackageManager:- "uv"}
pythonProjectFileExists=''${pythonProjectFileExists:- false}


copier copy "$TEMPLATE_DIR" "$dst_path" --trust --data "_python_package_manager_default=$pythonPackageManager" --data "_python_project_file_exists=$pythonProjectFileExists"