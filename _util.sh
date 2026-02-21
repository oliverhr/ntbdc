#!/usr/bin/env bash
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# LOAD CONFIG ENV
# -----------------------------------------------------------------------------
source config.env
if [ -f config.dist.env ]; then
    echo 'Source DIST .env file'
    source config.dist.env
fi

# -----------------------------------------------------------------------------
# SET RUNTIME CONFIG FILE
# -----------------------------------------------------------------------------
CONFIG_PATH='nautobot_config.dist.py'
if [[ ! -f $CONFIG_PATH ]]; then
    CONFIG_PATH='nautobot_config.py'
    echo 'Using default Nautobot config file'
else
    echo 'Using DIST Nautobot config file'
fi
COMPOSE_ARGS["NAUTOBOT_CONFIG_FILE"]=$CONFIG_PATH

# -----------------------------------------------------------------------------
# SET FULLY QUALIFIED IMAGE NAME
# -----------------------------------------------------------------------------
IMG="networktocode/nautobot"
if [[ -v $COMPOSE_ARGS["IMAGE_NAME"] && -n "${COMPOSE_ARGS["IMAGE_NAME"]}" ]]; then
    IMG=$COMPOSE_ARGS["IMAGE_NAME"]
    unset COMPOSE_ARGS["IMAGE_NAME"]
fi

TAG="${COMPOSE_ARGS["NAUTOBOT_VERSION"]}-py${COMPOSE_ARGS["PYTHON_VERSION"]}"
if [[ -v $COMPOSE_ARGS["TAG"] && -n "${COMPOSE_ARGS["TAG"]}" ]]; then
    $TAG=$COMPOSE_ARGS["TAG"]
    unset COMPOSE_ARGS["TAG"]
fi

COMPOSE_ARGS["NAUTOBOT_IMAGE_NAME"]="$IMG:$TAG"

# -----------------------------------------------------------------------------
# BUILD_ARGS
# -----------------------------------------------------------------------------
COMPOSE_BUILD_ARGS=''
for key in "${!COMPOSE_ARGS[@]}"; do
    COMPOSE_BUILD_ARGS+="--build-arg $key "
    export $key=${COMPOSE_ARGS[$key]}
done

# -----------------------------------------------------------------------------
# COMPOSE_FILES
# -----------------------------------------------------------------------------
COMPOSE_FILE=$(IFS=":"; echo "${COMPOSE_FILES[*]}")

# -----------------------------------------------------------------------------
export COMPOSE_FILE
export COMPOSE_BUILD_ARGS

echo ----------------------------- Configuration ------------------------------
echo PYTHON_SUPPORTED_RANGE: "$PYTHON_SUPPORTED_RANGE"
echo NAUTOBOT_VERSION: "$NAUTOBOT_VERSION"
echo PYTHON_VERSION: "$PYTHON_VERSION"
echo COMPOSE_DIR: "$COMPOSE_DIR"
echo PROJECT_NAME: "$PROJECT_NAME"
echo IMAGE_NAME: "$IMG:$TAG"
echo --------------------------------------------------------------------------
