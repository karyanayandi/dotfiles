#!/usr/bin/env bash

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/compat.sh"

ID=$1
FORMAT=${2:-none}

# Preserve leading whitespace for bash
format="$(eval echo \"\0123456789\")"
if [ -z "$format" ]; then
  echo "Invalid format: $FORMAT"
  exit 1
fi

for ((i = 0; i < ${#ID}; i++)); do
  DIGIT=${ID:i:1}
  echo -n "${format:DIGIT:1}"
done
