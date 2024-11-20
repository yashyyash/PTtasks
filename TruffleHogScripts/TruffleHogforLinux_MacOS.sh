#!/bin/bash

# Check if inside a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "This script must be run inside a git repository."
  exit 1
fi

# Determine the operating system and architecture
OS=$(uname -s)
ARCH=$(uname -m)

BASE_URL="https://github.com/trufflesecurity/trufflehog/releases/download/v3.83.7"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="trufflehog"

case "$OS" in
    Darwin)
        if [ "$ARCH" == "x86_64" ]; then
            FILE="trufflehog_3.83.7_darwin_amd64.tar.gz"
        elif [ "$ARCH" == "arm64" ]; then
            FILE="trufflehog_3.83.7_darwin_arm64.tar.gz"
        else
            echo "Unsupported architecture: $ARCH for OSX"
            exit 1
        fi
        ;;
    Linux)
        if [ "$ARCH" == "x86_64" ]; then
            FILE="trufflehog_3.83.7_linux_amd64.tar.gz"
        elif [ "$ARCH" == "aarch64" ]; then
            FILE="trufflehog_3.83.7_linux_arm64.tar.gz"
        else
            echo "Unsupported architecture: $ARCH for Linux"
            exit 1
        fi
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

echo "Downloading $FILE from $BASE_URL"
curl -LO "$BASE_URL/$FILE"
tar -xzvf "$FILE"
echo "Moving the binary to $INSTALL_DIR"
sudo mv "$BINARY_NAME" "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
rm "$FILE"

echo "Setting up a Python virtual environment..."
python3 -m venv venv

echo "Activating the virtual environment..."
source venv/bin/activate

echo "Installing pre-commit..."
pip install pre-commit

echo "Configuring pre-commit for TruffleHog..."
cat <<EOL > .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: trufflehog
        name: TruffleHog
        description: Detect secrets in your data.
        entry: bash -c 'trufflehog git file://. --since-commit HEAD --fail'
        language: system
        stages: ["pre-commit", "pre-push"]
EOL

echo "Installing pre-commit hook..."
pre-commit install

echo "Pre-commit and TruffleHog setup complete."
