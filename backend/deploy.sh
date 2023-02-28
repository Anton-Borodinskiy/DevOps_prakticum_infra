#!/bin/bash
set +e

sudo docker login ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}
sudo docker network create -d bridge sausage-store || true
docker-compose pull

echo -e "PSQL_DATASOURCE=${SPRING_DATASOURCE_URL}\VAULT_TOKEN=${SPRING_CLOUD_VAULT_TOKEN}" | sudo tee /home/student/blue_green_env

while read LINE; do export "$LINE"; done < /home/student/blue_green_env

if [[ $(docker container inspect -f '{{.State.Running}}' backend-blue) = true ]]
then
    echo "Blue continer is now running"
    docker-compose up -d --force-recreate backend-green
    green_status=$(docker container inspect -f '{{.State.Health.Status}}' backend-green)
    until [ "$green_status" = "healthy" ]
    do
      green_status=$(docker container inspect -f '{{.State.Health.Status}}' backend-green)
      echo $green_status
      sleep 10
    done
    echo "Green container is up!"
    docker stop backend-blue

elif [[ $(docker container inspect -f '{{.State.Running}}' backend-green) = true ]]
then
    echo "Green contianer is now running"
    docker-compose up -d --force-recreate backend-blue
    blueStatus=$(docker container inspect -f '{{.State.Health.Status}}' backend-blue)
    until [ "$blue_status" = "healthy" ]
    do
      blueStatus=$(docker container inspect -f '{{.State.Health.Status}}' backend-blue)
      echo $blue_status
      sleep 10
    done
    echo "Blue container is up!"
    docker stop backend-green
else
    # Starting blue if all container is inactive
    echo "All backend containers is inacive. Start blue..."
    docker-compose up -d --force-recreate backend-blue
    blueStatus=$(docker container inspect -f '{{.State.Health.Status}}' backend-blue)
    until [ "$blue_status" = "healthy" ]
    do
      blueStatus=$(docker container inspect -f '{{.State.Health.Status}}' backend-blue)
      echo $blue_status
      sleep 10
    done
    echo "Blue container is up!"
fi