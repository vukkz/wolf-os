#!/usr/bin/env bash
# Commits made on Windows can lose the "executable" flag, so set it here.
set -euo pipefail

chmod 0755 /usr/bin/wolf-security-check /usr/libexec/wolf-os-look
