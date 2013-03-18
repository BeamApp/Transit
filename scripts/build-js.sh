#!/bin/sh
set -e
set -o pipefail

pushd `pwd`
cd ..
npm install
npm update
npm test 2>&1 | scripts/grunt_jasmine_test2junit.py
popd