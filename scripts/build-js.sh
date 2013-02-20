#!/bin/sh

pushd `pwd`
cd ..
npm update
npm test 2>&1 | scripts/grunt_jasmine_test2junit.py
popd