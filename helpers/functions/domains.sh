#!/usr/bin/env bash

function dockerDomains() {
    D_ENVS=($(echo "${!DOMAIN_*}"))
    RESULT=""

    for env_name in "${D_ENVS[@]}"; do
        RESULT="$RESULT ${!env_name}"
    done

    echo "$RESULT"
}
