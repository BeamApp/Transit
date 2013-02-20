#!/bin/sh

pushd `pwd`
cd ..
npm update
npm test	
popd