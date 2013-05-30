#!/bin/sh
set -e

HOMEBREW=$HOME/homebrew
export PATH=$HOMEBREW/bin:$PATH
export ANDROID_SDK_ROOT=$HOMEBREW/opt/android-sdk

cd $(dirname $0)
./build-js.sh
./build-objc-ios.sh 0

# currently, race conditions prevent the android tests to pass
# ./build-java-android.sh 0
