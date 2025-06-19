@echo off
cd project
call setup-env.bat
cmake --build .
echo --------DONE--------