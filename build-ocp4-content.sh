#!/bin/bash

git checkout -b $branch --track origin/$branch
git log -1
pushd build
cmake ..
popd
./build_product ocp4
pushd build
ctest
popd
