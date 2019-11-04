#!/bin/bash

git checkout -b $branch --track origin/$branch
pushd build
cmake ..
popd
./build_product --debug ocp4
pushd build
ctest
popd
