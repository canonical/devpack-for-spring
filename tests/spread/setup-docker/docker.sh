#!/usr/bin/env bash

set -e

# Manually install "docker" from our given setup
devpack-for-spring setup --file setup.yaml

# Need to run "newgrp" to refresh our shell
newgrp docker

# Check that the user is assigned to the "docker" group
id -nG $USER | grep -qw docker

# Finally uninstall our setup for further testing
devpack-for-spring setup --uninstall --file setup.yaml
