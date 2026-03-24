#!/bin/sh
# You can find the latest version of this script at https://raw.githubusercontent.com/angrave/tealeaves/refs/heads/gh-pages/opencode-in-docker.sh
# ProTip: Read the offical opencode documentation!
#
# Quick Getting Started tips:
# This uses Docker (https://docs.docker.com/desktop/) to add some security; it isolates models from the rest of your system
# You need to know how to use the terminal

# Create a new directory e.g., "hello-ai", change to that directory and then run this script
# It will mount that directory and download the official opencode docker image
# Type /connect then search for ncsa to connect to lumen (it will ask you for the api key)

# Type "Hello" or "Create a file hello.py that prints hello world"
# Type /exit to exit

export OPENCODE_CONFIG_CONTENT=$(cat <<EOF
{
  "provider": {
    "llm.ncsa.illinois.edu": {
      "models": {
              "qwen3-coder-next": {"name": "qwen3-coder-next" }
              },
      "options": {
              "baseURL": "https://llm.ncsa.illinois.edu/v1"
      }
    },
    "lumen.ncsa.illinois.edu": {
      "models": {
              "qwen3-coder-next": {"name": "qwen3-coder-next" }
              },
      "options": {
              "baseURL": "https://lumen.ncsa.illinois.edu/v1"
      }
    }
  }
}
EOF
)

GRAY='\033[0;37m'
RED='\033[0;91m'
YELLOW='\033[0;33m'
NORM='\033[0m'


if ! docker info >/dev/null ; then
   printf "${RED}You need docker to be installed and running${NORM}"
   return
fi


#  Change to true to skip searching for files that belog to root
SKIP_ROOT_CHECK=false

if [ "$(id -u)" -ne 0 ] && [ "$SKIP_ROOT_CHECK" != "true" ] ; then
   printf "Checking for root-owned files in ${GRAY}~/.local/share${NORM} and ${GRAY}.${RED}\n"
   if find ~/.local/share .  -user root -print -quit | grep . ; then
     printf "${NORM}There is at least one file or directory owned as root.\nPlease fix e.g,\n"
     printf "${YELLOW}sudo chown -R $USER:$USER ~/.local/share .${NORM}\n\n"
     printf "Or set ${YELLOW}SKIP_ROOT_CHECK=true${NORM} in ${YELLOW}$0${NORM}\n"
     return 1
   fi
   printf "${NORM}"
fi


mkdir -p ~/.local/share/opencode-dockerized

OPENCODE_IMAGE="ghcr.io/anomalyco/opencode:latest"

# Comment out this line if you don't automatically want the latest version
docker pull "$OPENCODE_IMAGE"

# The -v mount syntax creates our own ~/.local/share/opencode-dockerized if it does not exist
# You could mount ~/.local/share/opencode instead
docker run -it --rm \
  -u $(id -u):$(id -g) \
  -e OPENCODE_CONFIG_CONTENT \
  -e HOME=/tmp/opencode \
  --workdir /workspace \
  -v "$(pwd):/workspace" \
  -v ~/.local/share/opencode-dockerized/:/tmp/opencode/ \
  "$OPENCODE_IMAGE" "$@"
