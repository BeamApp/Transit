#!/bin/sh
set -ev

# skip custom install of homebrew (introduced to get android running)
#
# HOMEBREW=$HOME/homebrew
# mkdir $HOMEBREW
# curl -L https://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C $HOMEBREW
# export PATH=$HOMEBREW/bin:$PATH

brew install phantomjs
which phantomjs || (echo "PhantomJS not in PATH" && exit 1)

brew install xctool
brew install appledoc

which pod
pod --version
echo "after ersion"
cat /usr/bin/pod
gem install cocoapods

# android build currently not supported on travis => skip installation
#
# brew install android-sdk
# which android || (echo "Android not in PATH" && exit 1)
#
# android update sdk -u --filter platform-tools,android-17,system-image,extra-intel-Hardware_Accelerated_Execution_Manager
# echo "no" | android create avd -n default -t android-17 -b x86
