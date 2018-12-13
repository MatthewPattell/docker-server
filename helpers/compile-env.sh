#!/usr/bin/env bash

for i in "$@"
do
case $i in
    -e=*|--env-file=*)
    ENV_FILES="${i#*=}"
    shift
    ;;
    *)
          # unknown option
    ;;
esac
done

ACTION=$1
CURRENT_DIR="${BASH_SOURCE%/*}"
source "$CURRENT_DIR/functions/base.sh"

# Get package vendor dir
VENDOR_DIR=$(dirname $CURRENT_DIR)

# Get vendor parent dir
VENDOR_PARENT_DIR=$(sed -n -e 's/\(^.*\)\(\(\/vendor\).*\)/\1/p' <<< "$VENDOR_DIR")
# Get vendor common dir
VENDOR_COMMON_DIR=$(sed -n -e 's/\(^.*\)\(\(\/vendor\).*\)/\2/p' <<< "$VENDOR_DIR")

# Add default env to config
ENV_FILES="${VENDOR_DIR}/docker/.env-default,${ENV_FILES}"

# Detect server init
[ "$ACTION" = "init" ] && return

# Handle env files
SERVER_ENVS=(" ")
SERVER_ENVS_RECOMPILE_NAMES=(" ")
SERVER_ENVS_RECOMPILE_VALUES=()
IFS=',' read -ra ADDR <<< "$ENV_FILES"
for ENV_FILE in "${ADDR[@]}"; do
    ENV_FILE_FULL_PATH=$(realpath "$ENV_FILE")

    if [ ! -f "$ENV_FILE_FULL_PATH" ]; then
        echo "Env file does not exist (skip): $ENV_FILE"
    else
        # Getting environments for using in current and parent script
        # This environments will be passed in docker compose files
        set -a
        . $ENV_FILE_FULL_PATH
        set +a

        while IFS='=' read -r name value; do
            case "$name" in \#*) continue ;; esac
            if [ ! -z "$name" ] && [ ! -z "$value" ]; then
                # Collect the environments, which will be added to result file
                if [[ ! ${SERVER_ENVS[@]} =~ " $name " ]] &&
                    [[ ! ${SERVER_ENVS[@]} =~ "$name " ]] &&
                    [[ ! ${SERVER_ENVS[@]} =~ " $name" ]]; then
                    SERVER_ENVS+=("$name")
                fi

                # Collect the environments, which will be recompile
                if [[ $value = *"\${"* ]]; then
                    if [[ ! ${SERVER_ENVS_RECOMPILE_NAMES[@]} =~ " $name " ]] &&
                        [[ ! ${SERVER_ENVS_RECOMPILE_NAMES[@]} =~ "$name " ]] &&
                        [[ ! ${SERVER_ENVS_RECOMPILE_NAMES[@]} =~ " $name" ]]; then
                        SERVER_ENVS_RECOMPILE_NAMES+=("$name")
                    fi

                    nameIndex=$(indexOf $name ${SERVER_ENVS_RECOMPILE_NAMES[@]})

                    SERVER_ENVS_RECOMPILE_VALUES[$nameIndex]=$value
                fi
            fi
        done < $ENV_FILE_FULL_PATH
    fi
done

# Remove first space (empty element)
SERVER_ENVS=("${SERVER_ENVS[@]:1}")
SERVER_ENVS_RECOMPILE_NAMES=("${SERVER_ENVS_RECOMPILE_NAMES[@]:1}")

# Recompile environments temp file
if [ ! -z $PROJECT_ENV_PATH_FORCE ]; then
    TMP_RECOMPILE_ENVS="${PROJECT_ENV_PATH_FORCE}/.env-tmp"
else
    TMP_RECOMPILE_ENVS="${PROJECT_DOCKER_FOLDER}/.env-tmp"
fi

# Echo recompile envs to temp file
echo -n "" > $TMP_RECOMPILE_ENVS
for recompile_env_name_index in ${!SERVER_ENVS_RECOMPILE_NAMES[@]}; do
    recompile_env_name=${SERVER_ENVS_RECOMPILE_NAMES[$recompile_env_name_index]}
    echo "$recompile_env_name=${SERVER_ENVS_RECOMPILE_VALUES[$recompile_env_name_index]}" >> $TMP_RECOMPILE_ENVS
done
# Recompile && remove tmp file
. "$TMP_RECOMPILE_ENVS"
rm $TMP_RECOMPILE_ENVS

# Get realpath docker compose files by default
SERVICES_PATHS=""

for SERVICE in $SERVICES; do
    if [ "${SERVICE: -3}" = "yml" ]; then
        if [ "${SERVICE:0:2}" = "!!" ]; then
            SERVICES_PATHS="${SERVICES_PATHS} -f $(realpath "${VENDOR_DIR}/docker/${SERVICE: 2}")"
        else
            SERVICES_PATHS="${SERVICES_PATHS} -f $(realpath "$SERVICE")"
        fi
    fi
done

export SERVICES=$SERVICES_PATHS

# Generated env path
export PROJECT_ENV_PATH="${PROJECT_DOCKER_FOLDER}/.env"
ENV_PATH=$PROJECT_ENV_PATH

if [ ! -z $PROJECT_ENV_PATH_FORCE ]; then
    ENV_PATH="${PROJECT_ENV_PATH_FORCE}/.env-compiled"
fi

# if action = down, keep and export old environments
if [ "$ACTION" = "down" ] || [ "$ACTION" = "restart" ]; then
    if [ -f "$PROJECT_ENV_PATH" ]; then
        set -a
        . $PROJECT_ENV_PATH
        set +a
    fi

    return
fi

# Collect all project environment to result temp env file
if [ "$ENV_PATH" != "" ]; then
    PROJECT_ENV_PATH_TMP=$(dirname "$ENV_PATH")
    if [ -d "$PROJECT_ENV_PATH_TMP" ]; then
        IFS=$'\n' SERVER_ENVS=($(sort <<<"${SERVER_ENVS[*]}"))
        unset IFS

        echo -n "" > "${ENV_PATH}"
        for ENV_NAME in ${SERVER_ENVS[@]}; do
            case "${!ENV_NAME}" in
                *\ * )
                    echo "$ENV_NAME=\"${!ENV_NAME}\"" >> ${ENV_PATH}
                ;;
                *\=* )
                    echo "$ENV_NAME=\"${!ENV_NAME}\"" >> ${ENV_PATH}
                ;;
                *)
                    echo "$ENV_NAME=${!ENV_NAME}" >> ${ENV_PATH}
                ;;
            esac
        done
    else
        echo "Folder does not exist: $PROJECT_ENV_PATH_TMP"
        exit 1;
    fi
fi