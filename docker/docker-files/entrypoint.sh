#!/usr/bin/env bash
set -exu

# Do not allow container to be started as non-root user
if (( "$(id -u)" != 0 )); then
    echo "You must run the container as root. To specify a custom user,"
    echo "use the NOVADOOM_UID and NOVADOOM_GID environment variables"
    exit 1
fi

 # Create the group for the server process
[[ -n "$NOVADOOM_GID" ]] && GID_OPTION="--gid $NOVADOOM_GID"
groupadd novadoom --force ${GID_OPTION-}

# Create the user for the server process
[[ -n "$NOVADOOM_UID" ]] && UID_OPTION="--uid $NOVADOOM_UID"
useradd doomguy --create-home ${UID_OPTION-} \
    --shell /sbin/nologin \
    --group novadoom \
    || true # Do not fail if user already exists

# Start the novadoom-server process with local user & group
gosu doomguy:novadoom novadoom-server -host "$@"
