#!/usr/bin/env bash
# Run PyLoN against a separate, pinned Space ROS installation on Linux.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
image="${PYLON_SPACEROS_IMAGE:-pylon-spaceros:jazzy-2026.07.0}"
container="${PYLON_SPACEROS_CONTAINER:-pylon-spaceros}"
usage() {
    cat <<'USAGE'
Usage: ./spaceros.sh COMMAND [arguments]
  build             Build the current core ROS sources against Space ROS.
  run [bridge args] Start the bridge (Ctrl+C stops it).
  shell             Open a new Space ROS shell.
  exec COMMAND ...  Run a command in the running bridge container.
  test              Run the bridge and vehicle control tests in Space ROS.
  stop              Stop the running bridge container.
Environment: PYLON_SPACEROS_IMAGE, PYLON_SPACEROS_CONTAINER, ROS_DOMAIN_ID,
             ROS_AUTOMATIC_DISCOVERY_RANGE (default LOCALHOST).
Rebuild after changing ROS sources. Host ~/ros2_ws is not used by the image.
USAGE
}
action="${1:-help}"
if (($#)); then shift; fi
case "$action" in
    help|-h|--help) usage; exit 0;;
    build|run|shell|exec|test|stop) ;;
    *) usage >&2; exit 2;;
esac
command -v docker >/dev/null || { echo 'Docker is required. See docs/guide/space-ros.md.' >&2; exit 1; }
interactive=()
if [[ -t 0 && -t 1 ]]; then interactive=(-it); fi
runtime=(--rm --init --network host
    -e "ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}"
    -e "ROS_AUTOMATIC_DISCOVERY_RANGE=${ROS_AUTOMATIC_DISCOVERY_RANGE:-LOCALHOST}")
case "$action" in
    build)
        docker build -f "$repo_root/Docker/spaceros/Dockerfile" -t "$image" "$@" "$repo_root";;
    run)
        exec docker run "${runtime[@]}" "${interactive[@]}" --name "$container" "$image" \
            ros2 run pylon_bridge udp_bridge --host 127.0.0.1 "$@";;
    shell)
        exec docker run "${runtime[@]}" "${interactive[@]}" "$image" bash --norc;;
    exec)
        (($#)) || { echo 'exec requires a command' >&2; exit 2; }
        exec docker exec "${interactive[@]}" "$container" /pylon-entrypoint.sh "$@";;
    test)
        # Use a private container network so test nodes cannot reach a running game.
        exec docker run --rm --init "$image" bash -ec '
            python3 -m pytest -q src/pylon_bridge/test
            python3 -m pytest -q src/pylon_vehicle_control/test
        ';;
    stop) exec docker stop "$container";;
esac
