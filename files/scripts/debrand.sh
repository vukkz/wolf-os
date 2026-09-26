#!/usr/bin/env bash
# Replace what's left of Fedora's own branding with Wolf OS.
set -euo pipefail

# KDE's Welcome Center: Fedora's intro text and pages -> Wolf Welcome.
# rpm -e removes only this package (dnf would also clean up its dependencies, one of
# which sets up Flathub). It must happen before copying ours: removing the package would
# otherwise delete the intro file at the same path.
if rpm -q plasma-welcome-fedora >/dev/null 2>&1; then
    rpm -e plasma-welcome-fedora
fi
welcome=/usr/share/plasma/plasma-welcome
mkdir -p "$welcome/extra-pages"
cp /usr/share/wolf-os/welcome/intro-customization.desktop "$welcome/"
cp /usr/share/wolf-os/welcome/extra-pages/*.qml "$welcome/extra-pages/"
ls -l "$welcome" "$welcome/extra-pages"
