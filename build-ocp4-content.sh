#!/bin/bash

git checkout ocp4
pushd build
cmake ..
popd
./build_product ocp4
pushd build
ctest
popd
