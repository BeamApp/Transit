#!/bin/sh
set -e

brew install phantomjs

cd $(dirname $0)
./build-js.sh
./build-objc-ios.sh 0