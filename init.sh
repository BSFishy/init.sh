#!/usr/bin/env bash

set -euo pipefail

print_step() {
  local message="$1"
  local border_char="${2:-#}"
  local message_length=${#message}
  local border_length=$((message_length + 4))

  printf "\n"
  printf "%*s\n" "$border_length" | tr ' ' "$border_char"
  printf "%s %s %s\n" "$border_char" "$message" "$border_char"
  printf "%*s\n" "$border_length" | tr ' ' "$border_char"
  printf "\n"
}

backup_existing_resources() {
  local backup_dir="$HOME/home-manager-backups"
  mkdir -p "$backup_dir"

  # List of files to backup
  local resources_to_backup=(".bashrc" ".profile" ".zshrc" ".zprofile")

  for resource in "${resources_to_backup[@]}"; do
    if [ -e "$HOME/$resource" ]; then
      local backup_path="$backup_dir/$(basename "$resource").$(date +%Y%m%d%H%M%S)"
      mv "$HOME/$resource" "$backup_path"
      echo "Backed up $HOME/$resource to $backup_path"
    fi
  done
}

ensure_installed() {
  local program="$1"
  if ! command -v "$program" >/dev/null 2>&1; then
    if command -v apt >/dev/null 2>&1; then
      sudo apt update -q
      sudo apt install --no-install-recommends -yq "$program"
    else
      echo "curl not found. please install it and run again."
      exit 1
    fi
  fi
}

if ! command -v nix >/dev/null 2>&1; then
  print_step "installing nix"
  ensure_installed "curl"

  # run the Determinate Systems Nix installer
  if curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; then
    echo "Nix installation completed successfully."
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    echo "Nix installation failed." >&2
    exit 1
  fi
fi

if ! command -v home-manager >/dev/null 2>&1; then
  print_step "installing home-manager"
  ensure_installed "git"

  # backup existing stuff for initial home manager installation
  backup_existing_resources

  # add home manager channel
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update

  # add home manager configuration
  mkdir -p ~/.config/home-manager
  git clone https://github.com/BSFishy/home.nix.git ~/.config/home-manager
  cat >~/.config/home-manager/home.nix <<EOF
{ config, pkgs, ... }:

{
  home.username = "$USER";
  home.homeDirectory = "$HOME";
  home.stateVersion = "24.11";
  imports = [ ./distro.nix ];
  programs.home-manager.enable = true;
  home.packages = [
    pkgs.nix
  ];
}
EOF

  # install home manager
  nix-shell '<home-manager>' -A install
fi

if [ -d "$HOME/.config/nvim" ]; then
  print_step "setting up neovim config"
  ensure_installed "git"

  mkdir -p ~/.config/nvim
  git clone https://github.com/BSFishy/init.lua.git ~/.config/nvim
fi

if [ ! -d "$HOME/shells" ]; then
  print_step "cloning shells project"
  ensure_installed "git"

  mkdir -p ~/shells
  git clone https://github.com/BSFishy/shells.git ~/shells
fi

if [ ! -d "$HOME/projects" ]; then
  mkdir -p ~/projects
fi

printf "\n\n"
printf "success!\n"
printf "please restart your session to enable configurations\n"
