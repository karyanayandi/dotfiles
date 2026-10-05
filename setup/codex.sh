#!/bin/bash

curl --proto '=https' --tlsv1.2 -fL -o install-arch.sh \
  https://persistent.oaistatic.com/codex-app-prod/linux/install-arch.sh
sudo bash install-arch.sh
