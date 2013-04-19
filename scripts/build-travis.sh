#!/bin/sh
set -e

export PATH=$HOME/homebrew/bin:$PATH

cd $(dirname $0)
./build-js.sh
./build-objc-ios.sh 0
./build-java-android.sh 0
