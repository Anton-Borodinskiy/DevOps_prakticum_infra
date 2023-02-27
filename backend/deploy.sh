#!/bin/bash
is-container-up() {
    local container=${1?"Usage: ${FUNCNAME[0]} container_name"}

    [ -n "$(docker --context remote ps -f name=${container} -q)" ]
    return $?
}

get-active-slot() {
    local image=${1?"Usage: ${FUNCNAME[0]} image_name"}

    if is-container-up ${image}-blue && is-container-up ${image}-green; then
        echo "Collision detected! Stopping ${image}-green..."
        docker-compose -H ssh://${DEV_USER}@${DEV_HOST} rm -s -f backend-green
        return 0  # BLUE
    fi
    if is-container-up ${image}-blue && ! is-container-up ${image}-green; then
        return 0  # BLUE
    fi
    if ! is-container-up ${image}-blue; then
        return 1  # GREEN
    fi
}

get-service-status() {
    local usage_msg="Usage: ${FUNCNAME[0]} image_name deployment_slot"
    local image=${1?usage_msg}
    local slot=${2?$usage_msg}

    case $image in
        # Add specific healthcheck paths for your services here
        *) local health_check_port_path=":8080/actuator/health" ;;
    esac
    local health_check_address="http://${image}-${slot}${health_check_port_path}"
    echo "Requesting '$health_check_address' within the 'sausage-store_sausage-store' docker network:"
    docker --context remote run --rm --network sausage-store_sausage-store alpine \
        wget --timeout=1 --quiet --server-response $health_check_address
    return $?
}

deploy() {
    local image_name=${1?"Usage: ${FUNCNAME[0]} image_name"}

    if get-active-slot $image_name
    then
        local OLD=${image_name}-blue
        local old_slot=blue
        local new_slot=green
    else
        local OLD=${image_name}-green
        local new_slot=blue
        local old_slot=green
    fi
    local NEW=${image_name}-${new_slot}
    echo "Ensuring the '$NEW' container from previous deploy is removed..."
    docker-compose -H ssh://${DEV_USER}@${DEV_HOST} rm -s -f backend-${new_slot} || :
    echo "Deploying '$NEW' in place of '$OLD'..."
    docker-compose -H ssh://${DEV_USER}@${DEV_HOST} up -d --force-recreate backend-${new_slot}
    echo "Container started. Checking health..."
    for i in {1..20}
    do
        sleep 1
        if get-service-status backend $new_slot
        then
            echo "New '$NEW' service seems OK."
            sleep 2  # Ensure service is ready
            echo "The '$NEW' service is live!"
            sleep 2  # Ensure all requests were processed
            echo "Stopping '$OLD'..."
            docker-compose -H ssh://${DEV_USER}@${DEV_HOST} rm -s -f backend-${old_slot}
            echo "Deployment successful!"
            return 0
        fi
        echo "New '$NEW' service is not ready yet. Waiting ($i)..."
    done
    echo "New '$NEW' service did not raise, killing it. Failed to deploy T_T"
    docker-compose -H ssh://${DEV_USER}@${DEV_HOST} rm -s -f backend-${new_slot}
    return 5
}

deploy sausage-backend
