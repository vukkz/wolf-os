# Wolf OS commands. Run `ujust` to see them all.

# Show how locked-down this system is
[group('Wolf OS')]
security-check:
    @/usr/bin/wolf-security-check

# Add the Wolf OS kernel hardening boot arguments (reboot to apply)
[group('Wolf OS')]
harden-kargs:
    #!/usr/bin/bash
    set -euo pipefail
    current=" $(rpm-ostree kargs) "
    args=()
    while read -r arg; do
        [[ -z "$arg" ]] && continue
        [[ "$current" == *" $arg "* ]] || args+=("--append-if-missing=$arg")
    done < /usr/share/wolf-os/kargs
    if (( ${#args[@]} == 0 )); then
        echo "Already applied. If you haven't rebooted since, reboot now."
        exit 0
    fi
    sudo rpm-ostree kargs "${args[@]}"
    echo "Done. Reboot to apply. To undo: ujust unharden-kargs"

# Remove the Wolf OS kernel hardening boot arguments (reboot to apply)
[group('Wolf OS')]
unharden-kargs:
    #!/usr/bin/bash
    set -euo pipefail
    current=" $(rpm-ostree kargs) "
    args=()
    while read -r arg; do
        [[ -z "$arg" ]] && continue
        [[ "$current" == *" $arg "* ]] && args+=("--delete-if-present=$arg")
    done < /usr/share/wolf-os/kargs
    if (( ${#args[@]} == 0 )); then
        echo "None of the Wolf OS kernel arguments are set."
        exit 0
    fi
    sudo rpm-ostree kargs "${args[@]}"
    echo "Done. Reboot to apply."

# Enter the Wolf Lab (Kali tools in a container). "ujust lab root" = raw network access for Wi-Fi monitor mode and packet capture
[group('Wolf OS')]
lab mode="":
    #!/usr/bin/bash
    set -euo pipefail
    image="ghcr.io/vukkz/wolf-os-lab:latest"
    case "{{ mode }}" in
        "")
            name="wolf-lab"; root=(); podman=(podman); app="burpsuite"
            ;;
        root)
            name="wolf-lab-root"; root=(--root); podman=(sudo podman); app="wireshark"
            echo "Root lab: tools here get raw access to your network hardware."
            echo "Use it only when a tool needs it, and leave it when you're done."
            ;;
        *)
            echo "Usage: ujust lab [root]"; exit 1
            ;;
    esac
    # The lab gets its own home folder, so tool configs, histories and loot stay out of your real one
    lab_home="$HOME/WolfLab/$name"
    if ! "${podman[@]}" container exists "$name"; then
        echo "Creating $name from $image (the first time downloads a few GB)..."
        mkdir -p "$lab_home"
        distrobox create "${root[@]}" --yes --pull --name "$name" --image "$image" --home "$lab_home"
        if distrobox enter "${root[@]}" "$name" -- distrobox-export --app "$app" >/dev/null 2>&1; then
            echo "Added $app to your app menu."
        else
            echo "Couldn't add $app to the app menu. It still works: run '$app' inside the lab."
        fi
    fi
    # --no-workdir: start in the lab's home, not whatever folder ujust was run from
    distrobox enter "${root[@]}" --no-workdir "$name"

# Delete a Wolf Lab container so the next "ujust lab" starts fresh from the newest image
[group('Wolf OS')]
lab-reset mode="":
    #!/usr/bin/bash
    set -euo pipefail
    case "{{ mode }}" in
        "")   distrobox rm --force wolf-lab ;;
        root) distrobox rm --root --force wolf-lab-root ;;
        *)    echo "Usage: ujust lab-reset [root]"; exit 1 ;;
    esac
    echo "Removed. Files in ~/WolfLab were kept. Run 'ujust lab' to create a fresh one."

# Turn USBGuard on or off. When on, USB devices plugged in later are blocked until you allow them
[group('Wolf OS')]
toggle-usbguard:
    #!/usr/bin/bash
    set -euo pipefail
    if systemctl is-active --quiet usbguard; then
        sudo systemctl disable --now usbguard
        echo "USBGuard is OFF. All USB devices are allowed."
        exit 0
    fi
    echo "Allowing every USB device that's plugged in right now (keyboard, mouse, ...)."
    sudo sh -c 'usbguard generate-policy > /etc/usbguard/rules.conf && chmod 0600 /etc/usbguard/rules.conf'
    sudo systemctl enable --now usbguard
    echo "USBGuard is ON. To allow a new device:"
    echo "  sudo usbguard list-devices --blocked"
    echo "  sudo usbguard allow-device <number> -p    (-p remembers it)"

# Install Steam with MangoHud and gamescope (Flatpak, sandboxed)
[group('Wolf OS')]
setup-gaming:
    #!/usr/bin/bash
    set -euo pipefail
    flatpak install --system --noninteractive flathub com.valvesoftware.Steam
    branch=$(flatpak info --system --show-runtime com.valvesoftware.Steam | cut -d/ -f3)
    flatpak install --system --noninteractive flathub \
        "org.freedesktop.Platform.VulkanLayer.MangoHud//${branch}" \
        "org.freedesktop.Platform.VulkanLayer.gamescope//${branch}" \
        || echo "Couldn't install MangoHud/gamescope for runtime ${branch}. Steam works without them."
    echo
    echo "Done. Start Steam from the app menu."
    echo "Tip, per game (Properties > Launch Options):  MANGOHUD=1 gamemoderun %command%"
