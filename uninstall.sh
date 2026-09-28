#!/usr/bin/bash
set -e
echo "Removing bitcalc..."

if dpkg -l | grep -q bitcalc; then
  sudo apt-get remove -y bitcalc
fi

if [ -f /etc/apt/sources.list.d/bitcalc.sources ]; then
  echo "Removing bitcalc repository source..."
  sudo rm -f /etc/apt/sources.list.d/bitcalc.sources
  sudo apt-get update -qq
fi

echo "bitcalc has been successfully uninstalled from your system."
