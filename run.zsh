#!/bin/zsh

mkdir -p build
odin run src -out:build/site_generator -debug -- $@