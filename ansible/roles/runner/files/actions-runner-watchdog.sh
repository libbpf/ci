#!/usr/bin/env bash

# Systemd will restart the actions-runner container

docker ps --filter 'health=unhealthy' --format '{{.ID}} {{.Names}}' | while read -r container_id container_name
do
  echo "Container ${container_id} (${container_name}) is unhealthy, stopping it"
  docker exec "$container_id" kill -INT -- -1
  docker wait "$container_id"
done
