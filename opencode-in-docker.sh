#!/bin/sh
# You can find the latest version of this script at https://raw.githubusercontent.com/angrave/tealeaves/refs/heads/gh-pages/opencode-in-docker.sh
# ProTip: Read the offical opencode documentation!
# 
# Quick Getting Started tips:
# This uses Docker (https://docs.docker.com/desktop/) to add some security; it isolates models from the rest of your system
# You need to know how to use the terminal

# Create a new directory e.g., "hello-ai", change to that directory and then run this script
# It will mount that directory and download the official opencode docker image
# Type /connect then search for llm.ncsa.illinois.edu to connect to it (it will ask you for the api key)
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
        "baseURL": "https://llm.ncsa.illinois.edu/"
      }
    }
  }
}
EOF
)

# Use the latest official opencode image
docker pull ghcr.io/anomalyco/opencode:latest

# The -v mount syntax creates our own ~/.local/share/opencode-dockerized if it does not exist
# You could mount ~/.local/share/opencode instead
# 
if find ~/.local/share  -user root -print -quit | grep -q .
then
echo -e "Earlier versions of created configuration files and directories as root. Please fix then run me again e.g, \nsudo chown -R $USER:$USER ~/.local/share ."
else

mkdir -p ~/.local/share/opencode-dockerized
docker run -it --rm \
  -u $(id -u):$(id -g) \
  -e OPENCODE_CONFIG_CONTENT \
  -e HOME=/tmp/opencode \
  --workdir /workspace \
  -v "$(pwd):/workspace" \
  -v ~/.local/share/opencode-dockerized/:/tmp/opencode/ \
  ghcr.io/anomalyco/opencode:latest "$@"
fi


