#!/usr/bin/env bash
# Make the "wolf" zone (files/system/usr/lib/firewalld/zones/wolf.xml) the default.
# Stock Fedora desktops default to a zone that allows incoming ports 1025-65535.
set -euo pipefail

firewall-offline-cmd --set-default-zone=wolf
firewall-offline-cmd --get-default-zone
