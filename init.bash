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

install_package() {
	local program="$1"
	if command -v apt-get >/dev/null 2>&1; then
		sudo DEBIAN_FRONTEND=noninteractive apt-get update -q
		sudo DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -yq "$program"
	else
		echo "$program not found. please install it and run again."
		exit 1
	fi
}

ensure_installed() {
	local program="$1"
	if ! command -v "$program" >/dev/null 2>&1; then
		install_package "$program"
	fi
}

sudo -v

IS_NIXOS=false
if grep -q '^ID=nixos' /etc/os-release 2>/dev/null; then
	IS_NIXOS=true
fi

if ! $IS_NIXOS; then
	if ! command -v zsh >/dev/null 2>&1; then
		print_step "installing zsh"

		if [ -f "/etc/zsh/zshrc" ]; then
			sudo rm /etc/zsh/zshrc
		fi

		install_package "zsh"
	fi
fi

if ! command -v nix >/dev/null 2>&1; then
	print_step "installing nix"
	ensure_installed "curl"
	ensure_installed "ca-certificates"

	# run the Determinate Systems Nix installer
	if curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm; then
		echo "Nix installation completed successfully."
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	else
		echo "Nix installation failed." >&2
		exit 1
	fi
fi

print_step "installing configuration"
setsid nix --extra-experimental-features "nix-command flakes" --no-sandbox run github:BSFishy/nix-config/main </dev/tty >/dev/tty 2>&1

if ! $IS_NIXOS; then
	if id "matt" >/dev/null 2>&1; then
		current_shell=$(getent passwd matt | cut -d: -f7)
		if [ "$current_shell" != "/bin/zsh" ]; then
			print_step "changing shell to zsh"
			sudo usermod -s /bin/zsh matt
		fi
	fi
fi
