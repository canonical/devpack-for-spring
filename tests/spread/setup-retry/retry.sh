#!/usr/bin/env bash

set -e

# stop apt-get requests from working for 1 minute
flock -x /var/lib/apt/lists/lock sleep 60 &

# force a retry to continue until the lock is released
devpack-for-spring setup --retry=-1 --file setup.yaml

# post uninstall our setup (just to confirm lock is released)
devpack-for-spring setup --uninstall --file setup.yaml
