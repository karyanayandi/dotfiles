#!/bin/bash

paru -S corepack

corepack install --global \
  npm@latest \
  pnpm@latest \
  yarn@latest
