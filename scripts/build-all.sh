#!/bin/sh
set -e

cd $(dirname $0)
./build-js.sh
./build-objc-ios.sh
./build-java-android.sh