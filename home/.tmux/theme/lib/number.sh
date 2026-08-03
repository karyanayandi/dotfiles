#!/usr/bin/env bash

ID=$1
FORMAT=${2:-0123456789}

for ((i = 0; i < ${#ID}; i++)); do
  DIGIT=${ID:i:1}
  echo -n "${FORMAT:DIGIT:1}"
done
