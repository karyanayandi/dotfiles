#!/bin/bash

sudo git config --system core.editor nvim
git config --global user.name "Karyana Yandi"
git config --global user.email "karyana@yandi.me"
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=18000'
git config --global push.default simple
git config --global pull.rebase false
git config --global init.defaultBranch main

gh extension install github/gh-copilot --force
