#!/bin/sh
set -e

HOMEBREW=$HOME/homebrew
mkdir $HOMEBREW
curl -L https://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C $HOMEBREW
export PATH=$HOMEBREW/bin:$PATH

brew install phantomjs
brew install android-sdk
android update sdk -u --filter platform-tools,android-17,system-image,extra-intel-Hardware_Accelerated_Execution_Manager
echo "no" | android create avd -n default -t android-17 -b x86
