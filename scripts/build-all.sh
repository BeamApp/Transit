#!/bin/sh
set -e

cd $(dirname $0)
./build-js.sh
./build-objc-ios.sh
./build-objc-osx.sh
./build-java-android.sh