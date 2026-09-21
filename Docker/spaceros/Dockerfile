FROM osrf/space-ros:jazzy-2026.07.0@sha256:a7df4a7bbb7019b45842ce60f4fb7998dcc64ad383c02e9c76ce082031c39fe5

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN mkdir -p /home/spaceros-user/pylon_ws
WORKDIR /home/spaceros-user/pylon_ws

COPY LICENSE LICENSE
COPY --chown=spaceros-user:spaceros-user Ros2/pylon_interfaces src/pylon_interfaces
COPY --chown=spaceros-user:spaceros-user Ros2/pylon_bridge src/pylon_bridge
COPY --chown=spaceros-user:spaceros-user Ros2/pylon_vehicle_control src/pylon_vehicle_control
RUN source /opt/ros/spaceros/setup.bash && \
    colcon build --packages-up-to pylon_bridge pylon_vehicle_control \
      --executor sequential --cmake-args -DCMAKE_BUILD_TYPE=Release

COPY Docker/spaceros/entrypoint.sh /pylon-entrypoint.sh
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENTRYPOINT ["/pylon-entrypoint.sh"]
CMD ["ros2", "run", "pylon_bridge", "udp_bridge", "--host", "127.0.0.1"]
