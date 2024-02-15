#!/bin/bash

# Set default values for environment variables
CONFIG_DIR="${CONFIG_DIR:-/usr/src/app}"
CONFIG="$CONFIG_DIR/config.json"
FORCE_BUILD_BEFORE_START="${FORCE_BUILD_BEFORE_START:-false}"
NODEBB_INIT_VERB="${NODEBB_INIT_VERB:-install}"
SETUP="${SETUP:-}"

# Ensure write access to the config directory
mkdir -p "$CONFIG_DIR"
chmod -fR 760 "$CONFIG_DIR" 2> /dev/null || { echo "Panic: No write permission for $CONFIG_DIR"; exit 1; }

# Check if required environment variables are set
[[ -z $NODEBB_INIT_VERB ]] && { echo "Error: NODEBB_INIT_VERB is not set."; exit 1; }

# Install dependencies
pnpm install

# Handle setup or start based on conditions
if [[ -n $SETUP ]]; then
  echo "Setup environmental variable detected. Starting setup session."
  /usr/src/app/nodebb setup --config="$CONFIG"
elif [[ -f "$CONFIG" ]]; then
  echo "Config file exists at $CONFIG, assuming it is a valid config. Starting forum."
  [[ "$FORCE_BUILD_BEFORE_START" = true ]] && /usr/src/app/nodebb build --config="$CONFIG"
  /usr/src/app/nodebb start --config="$CONFIG"
else
  echo "Config file not found at $CONFIG. Starting installation session."
  /usr/src/app/nodebb "${NODEBB_INIT_VERB}" --config="$CONFIG"
fi
