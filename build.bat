@echo off
if not exist build mkdir build

if "%1"=="release" (
	echo Release build
	odin build src -out:build/site_generator.exe
) else (
	echo Debug build
	odin build src -out:build/site_generator_debug.exe -debug
)