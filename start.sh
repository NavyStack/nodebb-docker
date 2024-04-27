#!/bin/bash

set -e

# Function to set default values for environment variables
set_defaults() {
  export DEFAULT_USER="${CONTAINER_USER:-container}" 
  export DEFAULT_USER_ID="${CONTAINER_USER_ID:-1001}"
  export DEFAULT_GROUP_ID="${CONTAINER_GRP_ID:-1001}"
  export HOME_DIR="/home/$DEFAULT_USER"
  export APP_DIR="/usr/src/app/"
  export HOME="$HOME_DIR"
  export LOG_DIR="$APP_DIR/logs"
  export CONFIG_DIR="${CONFIG_DIR:-/opt/config}"
}

# Function for fix permissions
prepare() {
    # Check if the group exists, if not, create it with the specified GID
    getent group "$DEFAULT_USER" >/dev/null 2>&1 || groupadd -g "$DEFAULT_GROUP_ID" "$DEFAULT_USER"

    # Check if the user exists, if not, create it with the specified UID and GID
    id -u "$DEFAULT_USER" >/dev/null 2>&1 || useradd --shell /bin/bash -u "$DEFAULT_USER_ID" -g "$DEFAULT_GROUP_ID" -o -c "" -m "$DEFAULT_USER"

    mkdir -p "$HOME_DIR" "$APP_DIR" "$LOG_DIR" "$CONFIG_DIR"

    chown -R "$DEFAULT_USER_ID:$DEFAULT_GROUP_ID" "$HOME_DIR" "$APP_DIR" "$CONFIG_DIR"
}


set_defaults

prepare

echo "Starting with UID/GID: $(id -u "$DEFAULT_USER")/$(getent group "$DEFAULT_USER" | cut -d ":" -f 3)"

# Execute docker-entrypoint
exec /usr/local/bin/gosu "$DEFAULT_USER" docker-entrypoint.sh
