#!/bin/bash

paru -S uv

uv tool install --python 3.12 'code-index-mcp==2.17.1' || exit 1
