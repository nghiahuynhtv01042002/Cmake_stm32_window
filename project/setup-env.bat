@echo off
echo clean and make file
rmdir /s /q BUILD
mkdir BUILD
cd BUILD

echo Configuring toolchain
cmake -G "MinGW Makefiles" -DCMAKE_TOOLCHAIN_FILE=../arm-toolchain.cmake ..