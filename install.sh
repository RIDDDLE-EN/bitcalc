#!/usr/bin/bash
set -e
echo "Setting up bitcalc repository..."

sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl

cat << 'REPO' | sudo tee /etc/apt/sources.list.d/bitcalc.sources > /dev/null
Types: deb
URIs: https://RIDDDLE-EN.github.io/bitcalc
Suites: ./
Trusted: yes
REPO

echo "Installing bitcalc..."

sudo apt-get update -qq
sudo apt-get install -y bitcalc

echo "Success! bitcalc is now installed. Type 'bitcalc --help' to get started."
