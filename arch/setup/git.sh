#!/bin/bash

git config --global user.name "Karyana Yandi"
git config --global user.email "karyana@yandi.me"
sudo git config --system core.editor nvim
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=18000'
git config --global push.default simple
git config --global pull.rebase false
