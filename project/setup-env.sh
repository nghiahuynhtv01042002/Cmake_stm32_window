#!/bin/bash
# I will Update for linux in future
echo "Cleaning build directory"
rm -rf BUILD
mkdir BUILD
cd BUILD 
echo "Configuring toolchain"
cmake -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=../arm-toolchain.cmake ..

