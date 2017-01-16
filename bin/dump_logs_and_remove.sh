#!/usr/bin/env bash

for name in $(docker ps -a | grep Exit | tr -s " " | rev | cut -d' ' -f1 | rev | grep wog_ga)
do
  echo "[$name] Handling"
  echo "[$name] dumping logs"
  docker logs $name > ./game_outputs/$name.log
  echo "[$name] removing container"
  docker rm $name > /dev/null
  echo "[$name] done removing container"
done
