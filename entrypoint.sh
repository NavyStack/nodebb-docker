#!/bin/bash

# Set default values for environment variables
export CONFIG_DIR="${CONFIG_DIR:-/usr/src/app}"
export CONFIG=$CONFIG_DIR/config.json
export FORCE_BUILD_BEFORE_START="${FORCE_BUILD_BEFORE_START:-false}"
export NODEBB_INIT_VERB="${NODEBB_INIT_VERB:-install}"
export SETUP="${SETUP:-}"

# Ensure write access to the config directory
mkdir -p "$CONFIG_DIR"
chmod -fR 760 "$CONFIG_DIR" 2> /dev/null

if [[ ! -w $CONFIG_DIR ]]; then
  echo "Panic: No write permission for $CONFIG_DIR"
  exit 1
fi

# Check if required environment variables are set
if [[ -z $NODEBB_INIT_VERB ]]; then
  echo "Error: NODEBB_INIT_VERB is not set."
  exit 1
fi

# Install dependencies
pnpm install

# Handle setup or start based on conditions
if [[ -n $SETUP ]]; then
  echo "Setup environmental variable detected. Starting setup session."
  ./nodebb setup --config="$CONFIG"
elif [ -f "$CONFIG" ]; then
  echo "Config file exists at $CONFIG, assuming it is a valid config. Starting forum."
  if [ "$FORCE_BUILD_BEFORE_START" = true ]; then
    ./nodebb build --config="$CONFIG"
  fi
  ./nodebb start --config="$CONFIG"
else
  echo "Config file not found at $CONFIG. Starting installation session."
  ./nodebb "${NODEBB_INIT_VERB}" --config="$CONFIG"
fi
