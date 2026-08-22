#!/bin/bash

bun add -g \
  9router \
  @earendil-works/pi-coding-agent \
  @fission-ai/openspec@latest \
  @playwright/cli@latest \
  @playwright/mcp@latest \
  agent-browser@latest \
  autocannon@latest \
  firebase-tools@latest \
  neovim@latest \
  node-gyp@latest \
  opencode-goal-plugin \
  playwright@latest \
  playwriter@latest \
  tree-sitter@latest \
  wrangler@latest

npm i -g \
  pcu \
  pnpm \
  yarn

bun x skills add https://skills.sh/p/aKGonvnAA4p1fkdf
