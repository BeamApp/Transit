#!/bin/sh
set -ev

# skip custom install of homebrew (introduced to get android running)
#
# HOMEBREW=$HOME/homebrew
# mkdir $HOMEBREW
# curl -L https://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C $HOMEBREW
# export PATH=$HOMEBREW/bin:$PATH


#rvm install 2.0.0
#rvm use 2.0.0
#rvm gemset create travis
#rvm gemset use travis
echo $PATH

brew install node

which npm || (echo "npm not in PATH" && exit 1)

# workaround as describe in http://blog.npmjs.org/post/78085451721/npms-self-signed-certificate-is-no-more
npm install npm -g


brew install xctool
brew install appledoc

gem install cocoapods

brew install phantomjs
which phantomjs || (echo "PhantomJS not in PATH" && exit 1)



# android build currently not supported on travis => skip installation
#
# brew install android-sdk
# which android || (echo "Android not in PATH" && exit 1)
#
# android update sdk -u --filter platform-tools,android-17,system-image,extra-intel-Hardware_Accelerated_Execution_Manager
# echo "no" | android create avd -n default -t android-17 -b x86
