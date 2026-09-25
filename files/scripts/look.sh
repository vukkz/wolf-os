#!/usr/bin/env bash
# Wolf OS look: turns the SVG artwork (made by art/generate.mjs) into the app-menu icon,
# About-page logo, wallpapers and boot screen, and makes them the defaults.
set -euo pipefail

art=/usr/share/wolf-os/art

# --- Logo -----------------------------------------------------------------------------
install -Dm644 "$art/wolf-os-logo.svg" /usr/share/icons/hicolor/scalable/apps/wolf-os-logo.svg
# Fedora's app-menu button shows the "start-here" icon: point it at the wolf, and delete the
# fixed-size PNG copies of the Fedora logo, which would otherwise win over the SVG.
ln -sf wolf-os-logo.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg
find /usr/share/icons/hicolor -name 'start-here.png' -print -delete
if command -v gtk-update-icon-cache >/dev/null; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor
fi
mkdir -p /usr/share/pixmaps
rsvg-convert -w 256 -h 256 "$art/wolf-os-logo.svg" -o /usr/share/pixmaps/wolf-os-logo.png # About page

# --- Wallpapers (metadata.json for each comes from files/system) ----------------------
for name in night emblem; do
    dir="/usr/share/wallpapers/WolfOS-${name^}"
    mkdir -p "$dir/contents/images"
    for size in 3840x2160 2560x1440 1920x1080; do
        rsvg-convert -w "${size%x*}" -h "${size#*x}" "$art/wallpaper-$name.svg" -o "$dir/contents/images/$size.png"
    done
    rsvg-convert -w 400 -h 225 "$art/wallpaper-$name.svg" -o "$dir/contents/screenshot.png"
done
# The desktop, login screen and lock screen all default to /usr/share/wallpapers/Fedora
ln -sfn WolfOS-Night /usr/share/wallpapers/Fedora

# --- Boot screen (Plymouth). The initramfs module later bakes it into the boot image ----
theme=/usr/share/plymouth/themes/wolf-os
cp /usr/share/plymouth/themes/spinner/*.png "$theme/" # spinner, password box and lock icons
rsvg-convert -h 260 "$art/wolf-os-emblem.svg" -o "$theme/watermark.png"
plymouth-set-default-theme wolf-os
echo "Plymouth theme: $(plymouth-set-default-theme)"
