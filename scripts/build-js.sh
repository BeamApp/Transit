#!/bin/sh

pushd `pwd`
cd ..
npm update
grunt travis -v -no-color 2>&1 | scripts/grunt_jasmine_test2junit.py
popd