#!/bin/sh
# ProTip: Read the offical opencode documentation!
# 
# Quick Getting Started tips: 
# Create a new directory "hello-ai", cd to that directory and run this script
# It will mount that directory and download the offocial opencode docker image
# Type /connect then search for litellm.kooper.org to connect to it (it will ask you for the api key)
# Type "Hello" or "Create a file hello.py that prints hello world"
# Type /exit to exit

export OPENCODE_CONFIG_CONTENT=$(cat <<EOF
{
  "provider": {
    "litellm.kooper.org": {      
      "models": {
              "qwen3-coder-next": {"name": "qwen3-coder-next" }
              },
      "options": {
        "baseURL": "https://litellm.kooper.org/"
      }
    }
  }
}
EOF
)

# The -v mount syntax creates our own ~/.local/share/opencode-dockerized if it does not exist
# You could mount ~/.local/share/opencode instead

# Use official opencode image
docker run -it --rm \
  -e OPENCODE_CONFIG_CONTENT \
  --workdir /workspace \
  -v "$(pwd):/workspace" \
  -v ~/.local/share/opencode-dockerized/:/root/.local/share/opencode/ \
  ghcr.io/anomalyco/opencode:latest "$@"



