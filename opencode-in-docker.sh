#!/bin/sh

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

docker run -it --rm \
  -e OPENCODE_CONFIG_CONTENT \
  --workdir /workspace \
  -v "$(pwd):/workspace" \
  -v ~/.local/share/opencode-dockerized/:/root/.local/share/opencode/ \
  ghcr.io/anomalyco/opencode:latest "$@"
