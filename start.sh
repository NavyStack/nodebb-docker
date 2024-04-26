#!/bin/bash

set -e

# Function to set default values for environment variables
set_defaults() {
  export CONFIG_DIR="${CONFIG_DIR:-/opt/config}"
  export CONFIG="$CONFIG_DIR/config.json"
  export NODEBB_INIT_VERB="${NODEBB_INIT_VERB:-install}"
  export START_BUILD="${START_BUILD:-false}"
  export SETUP="${SETUP:-}"
  export PACKAGE_MANAGER="${PACKAGE_MANAGER:-npm}"
  export OVERRIDE_UPDATE_LOCK="${OVERRIDE_UPDATE_LOCK:-false}"
  export DEFAULT_USER="${CONTAINER_USER:-container}" 
  export DEFAULT_USER_ID="${CONTAINER_USER_ID:-1001}"
  export DEFAULT_GROUP_ID="${CONTAINER_GRP_ID:-1001}"
  export HOME_DIR="/home/$DEFAULT_USER"
  export APP_DIR="/usr/src/app/"
  export HOME="$HOME_DIR"
  export LOG_DIR="$APP_DIR/logs"
}

# Function to check if a directory exists and is writable
check_directory() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo "Error: Directory $dir does not exist. Creating..."
    mkdir -p "$dir" || {
      echo "Error: Failed to create directory $dir"
      exit 1
    }
  fi
  if [ ! -w "$dir" ]; then
    echo "Error: No write permission for directory $dir"
    exit 1
  fi
}

# Function to copy or link package.json and lock files based on package manager
copy_or_link_files() {
  local src_dir="$1"
  local dest_dir="$2"
  local package_manager="$3"
  local lock_file

  case "$package_manager" in
    yarn) lock_file="yarn.lock" ;;
    npm) lock_file="package-lock.json" ;;
    pnpm) lock_file="pnpm-lock.yaml" ;;
    *)
      echo "Unknown package manager: $package_manager"
      exit 1
      ;;
  esac

  # Check if source and destination files are the same
  if [ "$(realpath "$src_dir/package.json")" != "$(realpath "$dest_dir/package.json")" ]; then
    cp "$src_dir/package.json" "$dest_dir/package.json"
  fi

  if [ "$(realpath "$src_dir/$lock_file")" != "$(realpath "$dest_dir/$lock_file")" ]; then
    cp "$src_dir/$lock_file" "$dest_dir/$lock_file"
  fi

  # Remove unnecessary lock files in src_dir
  rm -f "$src_dir/"{yarn.lock,package-lock.json,pnpm-lock.yaml}

  # Symbolically link the copied files in src_dir to dest_dir
  ln -fs "$dest_dir/package.json" "$src_dir/package.json"
  ln -fs "$dest_dir/$lock_file" "$src_dir/$lock_file"
}

# Function to install dependencies using pnpm
install_dependencies() {
  case "$PACKAGE_MANAGER" in
    yarn) yarn install || {
      echo "Failed to install dependencies with yarn"
      exit 1
    } ;;
    npm) npm install || {
      echo "Failed to install dependencies with npm"
      exit 1
    } ;;
    pnpm) pnpm install || {
      echo "Failed to install dependencies with pnpm"
      exit 1
    } ;;
    *)
      echo "Unknown package manager: $PACKAGE_MANAGER"
      exit 1
      ;;
  esac
}

# Function to start setup session
start_setup_session() {
  local config="$1"
  echo "Starting setup session"
  exec /usr/src/app/nodebb setup --config="$config"
}

# Function to start forum
start_forum() {
  local config="$1"
  local start_build="$2"

  echo "Starting forum"
  if [ "$start_build" = true ]; then
    echo "Build before start is enabled. Building..."
    /usr/src/app/nodebb build --config="$config" || {
      echo "Failed to build NodeBB. Exiting..."
      exit 1
    }
  fi

  case "$PACKAGE_MANAGER" in
    yarn)
      yarn start --config="$config" --no-silent --no-daemon || {
        echo "Failed to start forum with yarn"
        exit 1
      }
      ;;
    npm)
      npm start -- --config="$config" --no-silent --no-daemon || {
        echo "Failed to start forum with npm"
        exit 1
      }
      ;;
    pnpm)
      pnpm start -- --config="$config" --no-silent --no-daemon || {
        echo "Failed to start forum with pnpm"
        exit 1
      }
      ;;
    *)
      echo "Unknown package manager: $PACKAGE_MANAGER"
      exit 1
      ;;
  esac
}

# Function to start installation session
start_installation_session() {
  local nodebb_init_verb="$1"
  local config="$2"

  echo "Config file not found at $config"
  echo "Starting installation session"
  exec /usr/src/app/nodebb "$nodebb_init_verb" --config="$config"
}

# Function for debugging and logging
debug_log() {
  local message="$1"
  echo "DEBUG: $message"
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

# Main function
main() {
  check_directory "$CONFIG_DIR"
  copy_or_link_files /usr/src/app "$CONFIG_DIR" "$PACKAGE_MANAGER"
  install_dependencies

  debug_log "PACKAGE_MANAGER: $PACKAGE_MANAGER"
  debug_log "CONFIG location: $CONFIG"
  debug_log "START_BUILD: $START_BUILD"

  if [ -n "$SETUP" ]; then
    start_setup_session "$CONFIG"
  fi

  if [ -f "$CONFIG" ]; then
    start_forum "$CONFIG" "$START_BUILD"
  else
    start_installation_session "$NODEBB_INIT_VERB" "$CONFIG"
  fi
}

# Execute main function
exec /usr/local/bin/gosu "$DEFAULT_USER" docker-entrypoint.sh
