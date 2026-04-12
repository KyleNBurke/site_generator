#!/bin/zsh

mkdir -p build
odin run . -out:build/site_generator -debug -- $@