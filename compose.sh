#!/usr/bin/env bash

usage() {
cat <<EOT
Usage: $0

Options:
    build         Build the images, by default uses cache, if don't
                  want to use cache add the flag [--no-cache].
    cli           Launch a shell inside the Nautobot container.
    debug         Set debug mode.
    destroy       Destroy everything: containers, volumes, images.
    migrate       Run migrations.
    nbshell       Launch an interactive nbshell session.
    shellplus     Launch an interactive nbshell plus session.
    start         Start the containers.
    restart       Restart the containers.
    stop          Stop the containers.
    help          Show this message and exit.
    ---

    ie:
           $0 build --no-cache
EOT
}

opt="$1"
if [ $# -eq 0 ] || [ $# -gt 2 ]; then
  usage
  exit 1
elif [ $# -eq 2 ] && [ "$opt" != "build" ]; then
  usage
  exit 1
fi

optarg=$2
case ${opt} in
  help ) # Display usage
    usage
    exit 0 ;;
  build ) # Build the images
    if [ ! -z "$optarg" ] && [ "$optarg" != '--no-cache' ]; then
      usage
      exit 1
    fi
    CMD+="build $optarg"
    ;;
  cli ) # Launch a shell inside the Nautobot container
    CMD="exec nautobot /bin/bash"
    ;;
  debug ) # Set debug mode
    CMD="up --timestamps"
    ;;
  start ) # Start container
    CMD="up --detach"
    ;;
  restart ) # Restart container
    CMD="restart"
    ;;
  shellplus ) # Launch an interactve nbshell plus session
      CMD="exec nautobot nautobot-server shell_plus"
      ;;
  nbshell ) # Launch an interactve nbshell session
    CMD="exec nautobot nautobot-server nbshell"
    ;;
  stop ) # Stop and remove container
    CMD="down"
    ;;
  destroy ) # Destroy container, volumes, images
    CMD="down --volumes --rmi all"
    ;;
  migrate ) # Run migrations
    CMD="exec nautobot nautobot-server migrate"
    ;;
  * )
    usage
    exit 1 ;;
esac

source ./_util.sh
docker \
  compose \
    --project-name "$PROJECT_NAME" \
    --project-directory "$COMPOSE_DIR" \
  ${CMD}

# vim: set ft=sh ts=4 sw=4 noet:
