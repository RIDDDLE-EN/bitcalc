#!/usr/bin/bash
set -e
echo "Setting up bitcalc repository..."

apt-get update -qq
apt-get install -y -qq ca-certificates curl

cat << 'REPO' | tee /etc/apt/sources.list.d/bitcalc.sources > /dev/null
Types: deb
URIs: https://RIDDDLE-EN.github.io/bitcalc
Suites: ./
Trusted: yes
REPO

echo "Installing bitcalc..."

apt-get update -qq
apt-get install -y bitcalc

echo "Success! bitcalc is now installed. Type 'bitcalc --help' to get started."
