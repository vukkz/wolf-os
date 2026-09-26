# Wolf OS security

Wolf OS aims for **hardening that doesn't get in your way**. Every setting here is on
by default unless marked *opt-in*. Each one lists what it protects against, what it
can break, and how to undo it. Run `ujust security-check` to see the live status.

Base: Fedora Atomic 44 (KDE Plasma) via Universal Blue. That already gives you
SELinux enforcing, a read-only `/usr`, atomic updates with rollback, and sandboxed
Flatpak apps. Everything below is added on top.

## Updates

| Setting | Why | Trade-off |
|---|---|---|
| Images signed with cosign (`cosign.pub`) | Your system only accepts updates signed with the Wolf OS key, so a hijacked registry can't push you a malicious OS | You must rebase with `ostree-image-signed:` once (see README) |
| Automatic updates (Universal Blue default) | Security fixes arrive without you remembering | Updates apply on the next reboot |
| Fedora version pinned (`image-version: 44`) | Big upgrades are a deliberate change, not a surprise | Moving to Fedora 45 is a manual edit of `recipe.yml` |

## Firewall: `files/system/usr/lib/firewalld/zones/wolf.xml`

The default zone is `wolf`: **all incoming connections are blocked** except DHCPv6
and mDNS (finding printers and devices on your LAN). Outgoing traffic isn't restricted.
Stock Fedora desktops allow incoming ports 1025–65535.

**Can break:** anything that needs other devices to connect *to* you. Open what you need:

| Feature | Command |
|---|---|
| KDE Connect | `sudo firewall-cmd --permanent --add-service=kdeconnect` |
| Steam Remote Play / LAN games | `sudo firewall-cmd --permanent --add-service=steam-streaming` |
| SSH into this machine | `sudo firewall-cmd --permanent --add-service=ssh` |
| Anything else | `sudo firewall-cmd --permanent --add-port=PORT/tcp` |

Then `sudo firewall-cmd --reload`. Undo everything: `sudo firewall-cmd --set-default-zone=FedoraWorkstation`.

## Kernel settings: `files/system/usr/lib/sysctl.d/90-wolf-hardening.conf`

| Setting | Why | Can break |
|---|---|---|
| `kernel.kptr_restrict=2`, `kernel.dmesg_restrict=1` | Hides kernel memory addresses and logs that exploits use to aim | `dmesg` needs `sudo` |
| `kernel.unprivileged_bpf_disabled=1`, `net.core.bpf_jit_harden=2` | BPF is a common kernel exploit path | Nothing for normal users |
| `kernel.kexec_load_disabled=1` | Stops an attacker with root from loading a different kernel | kdump crash dumps |
| `dev.tty.ldisc_autoload=0` | Blocks a class of TTY kernel exploits | Nothing common |
| `kernel.yama.ptrace_scope=1` | Programs can't read the memory of other programs you run (e.g. malware reading your browser) | Attaching a debugger to a running program needs `sudo` |
| `vm.mmap_rnd_bits=32`, `vm.mmap_rnd_compat_bits=16` | More ASLR randomness, so exploits have to guess harder | Nothing known |
| `fs.protected_*`, `fs.suid_dumpable=0` | Blocks file-trick attacks in shared folders like `/tmp`, and core dumps leaking secrets | Nothing common |
| No ICMP redirects, no source routing, `tcp_rfc1337` | Other machines on your network can't reroute your traffic | Nothing for a desktop |

To change one: put the same key in `/etc/sysctl.d/99-local.conf`, then run `sudo sysctl --system`.

**Deliberately left alone:**
- `rp_filter` stays at systemd's "loose" mode, because strict mode breaks many VPNs.
- `io_uring` stays enabled, because some apps and games need it.

## Kernel boot arguments: `ujust harden-kargs` (*run once*)

`slab_nomerge init_on_alloc=1 page_alloc.shuffle=1 randomize_kstack_offset=on vsyscall=none`
(the list is in `files/system/usr/share/wolf-os/kargs`)

These make kernel memory-corruption bugs much harder to exploit. The cost is a small
amount of performance and memory.
- `vsyscall=none` breaks only ancient (pre-2012) Linux programs. Windows games through Proton aren't affected.
- `init_on_free=1` was left out on purpose because of its bigger performance cost.

They're a `ujust` command rather than built into the image, because updates
through `rpm-ostree` don't apply kernel arguments from the image. Undo with `ujust unharden-kargs`.

## Blocked kernel modules: `files/system/usr/lib/modprobe.d/wolf-blacklist.conf`

These modules can't be auto-loaded:
- Rare network protocols (DCCP, SCTP, RDS, TIPC, and others) that have had many kernel bugs.
- FireWire, which allows direct memory access attacks.
- The `vivid` test driver.
- Some obscure filesystems.

**Can break:** FireWire audio interfaces and camcorders, which are very rare now.
HFS+ (Mac drives), UDF (discs) and exFAT still work.

## Network privacy: `files/system/usr/lib/NetworkManager/conf.d/90-wolf-privacy.conf`

- Each Wi-Fi network sees a different MAC address that stays the same for that network. Networks can't track you across locations, but captive portals and router reservations still work.
- Temporary IPv6 addresses are preferred for outgoing connections.

## USBGuard (*opt-in*): `ujust toggle-usbguard`

When it's on, only the USB devices plugged in when you turned it on are allowed.
A malicious USB stick pretending to be a keyboard gets blocked. It's off by default
because it's easy to lock yourself out of a new keyboard.

## Network trust: `wolf net`

Every Wi-Fi or wired network has a trust level. The first time you connect to one,
Wolf OS picks a safe default and sends a notification:
- **New Wi-Fi networks are public** (you might be in a café).
- **New wired networks are home.**

Change it any time with `wolf net home` or `wolf net public`. The file behind this
is `files/system/usr/lib/NetworkManager/dispatcher.d/90-wolf-network-trust`.

| | Home (zone `wolf`) | Public (zone `wolf-public`) |
|---|---|---|
| Incoming connections | Blocked, except device discovery (mDNS) | **All silently dropped**, including pings. Scanners see nothing |
| Announce this PC's name on the network (mDNS/LLMNR) | Yes | No |
| Send your hostname to the router (DHCP) | Yes | No |
| Wi-Fi MAC address | Stable for this network | **New random one every time you connect** |

**Can break on public networks:** casting to a TV, network printers and KDE Connect,
because they rely on devices finding each other. That's the point on a network you
don't control. Use `wolf net home` on networks you trust.

## Game Mode: `wolf game on`

A temporary mode for playing. **Everything it changes resets at reboot or with `wolf game off`.**
- Opens Steam Remote Play and Steam LAN game transfer (firewalld services `steam-streaming`,
  `steam-lan-transfer`), but **only on home networks**. On public networks they stay closed.
- Pauses automatic updates, so they don't take bandwidth or CPU mid-game.
- Switches to the *performance* power profile.

## Security levels: `wolf level`

One switch that moves a bundle of settings together. It stays until you change it.
The files are in `files/system/usr/share/wolf-os/levels/`.

| | gaming | balanced (default) | paranoid |
|---|---|---|---|
| Everything above in this file | ✔ | ✔ | ✔ |
| Steam Remote Play/LAN ports on home networks | Always open | Only in Game Mode | Only in Game Mode |
| Split-lock slowdown (`kernel.split_lock_mitigate`) | Off, as on SteamOS: fixes stutter in a few games | On | On |
| Encrypted DNS: every lookup goes to Quad9 over TLS, ignoring the network's DNS | | | ✔ |
| Reply to pings | Yes | Yes | No |
| io_uring, a kernel I/O interface with many past exploits | On | On | Off |
| Magic SysRq keyboard shortcuts | Sync only | Sync only | Off |
| TCP timestamps, which reveal uptime | On | On | Off |
| USBGuard | Your choice | Your choice | On |

Switching levels is instant and needs no reboot. **Levels never change kernel boot
arguments.** On Wolf OS that creates a new boot entry, which takes a minute, needs a
reboot, and pushes your previous OS version out of the rollback slot.

**Extra hardening you can add by hand:** wipe freed memory, so leftover passwords and
keys can't be read by an exploit. It costs a few percent of speed. Add it with
`sudo rpm-ostree kargs --append-if-missing=init_on_free=1` and reboot. Remove it with
`--delete-if-present=init_on_free=1`.

**Paranoid breaks some things:**
- Wi-Fi login pages (hotels, airports, trains) don't load, because DNS only goes to
  Quad9. Switch to `balanced`, log in, then switch back.
- A few apps that use io_uring can fail.
- Split-lock mitigation only exists on CPUs that detect split locks (mostly Intel).
  On other CPUs, that setting does nothing.

## Wolf Lab: `ujust lab`

The Kali tools live in a container (`lab/Containerfile`), not on the host. Here's
exactly what that does and doesn't protect.

**What it gives you:**
- No attack tools, and none of their thousands of dependencies, installed on the host system.
- Tools run as your user, not root. Only `ujust lab root` gets raw network access.
- The lab has its own home folder (`~/WolfLab`), so tool configs and loot stay separate.
- The lab image is rebuilt weekly and signed with the same key as the OS.

**What it doesn't do:** it is **not a sandbox**. Distrobox shares your user account
and can still reach your files (through `/run/host`), your display and your network.
Treat the lab like any program you run.
- Don't run untrusted binaries or malware samples in it.
- Use a separate virtual machine for those.

*Planned:* make `podman` refuse unsigned lab images, and add a "strict lab" mode
built on plain `podman` with no access to host files.

## Not included (and why)

| Thing | Why not |
|---|---|
| hardened_malloc | Crashes many Electron apps (Discord, VS Code). Too disruptive for a daily driver |
| Blocking unprivileged user namespaces | Breaks Flatpak and browser sandboxes unless done with custom SELinux policy |
| `lockdown=confidentiality` | Breaks hibernation and some drivers. Secure Boot already enables `integrity` mode |

## Reporting a security problem

Open an issue at https://github.com/vukkz/wolf-os/issues, or for anything sensitive
use GitHub's private vulnerability reporting on the repo's **Security** tab.
