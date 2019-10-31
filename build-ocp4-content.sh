#!/bin/bash

git checkout -b ocp4 --track origin/ocp4
pushd build
cmake ..
popd
./build_product ocp4
pushd build
ctest
popd
