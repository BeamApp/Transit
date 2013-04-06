#!/bin/sh
set -e

brew install phantomjs
android update sdk -u --filter platform-tools,android-17,system-image,extra-intel-Hardware_Accelerated_Execution_Manager
echo "no" | android create avd -n default -t android-17 -b x86