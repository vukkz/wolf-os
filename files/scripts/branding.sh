#!/usr/bin/env bash
# Rename the OS to Wolf OS (shown in the boot menu, fastfetch, system settings).
# ID stays "fedora" on purpose so Fedora tooling (dnf, toolbox, flatpak) keeps working.
set -euo pipefail

file=$(readlink -f /usr/lib/os-release) # Fedora symlinks this to a per-edition file
version=$(sed -n 's/^VERSION_ID=//p' "$file" | tr -d '"')

set_field() {
    local key=$1 value=$2
    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$file"
    else
        echo "${key}=\"${value}\"" >>"$file"
    fi
}

set_field NAME "Wolf OS"
set_field PRETTY_NAME "Wolf OS ${version}"
set_field HOME_URL "https://github.com/vukkz/wolf-os"
set_field BUG_REPORT_URL "https://github.com/vukkz/wolf-os/issues"
set_field DEFAULT_HOSTNAME "wolf-os"

cat "$file"
