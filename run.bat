@echo off
if not exist build mkdir build

@echo on
odin run . -out:build/site_generator.exe -debug -- %*