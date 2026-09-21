#!/usr/bin/env bash
set -eo pipefail
source /opt/ros/spaceros/setup.bash
source /home/spaceros-user/pylon_ws/install/local_setup.bash
exec "$@"
