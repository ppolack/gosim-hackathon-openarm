#!/usr/bin/env bash
set -euo pipefail

# Clone the repo
if [ ! -d "lerobot" ]; then
  echo "▶ Cloning huggingface/lerobot…"
  git clone https://github.com/huggingface/lerobot.git
fi


# Install dependencies
echo "▶ Installing lerobot in editable mode…"
pip install -e ./lerobot

echo "▶ Installing wandb…"
pip install wandb

