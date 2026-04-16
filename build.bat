@echo off
if not exist build mkdir build

@echo on
odin build . -out:build/site_generator.exe -debug