#!/bin/sh

set -e

cd $(dirname $0)

TESTS_PROJECT_NAME="TransitTestsIOS"
TESTS_PROJECT_ROOT="`cd ../tests/objc-ios; pwd`"

EXAMPLES_PROJECT_NAME="TransitExampleIOS"
EXAMPLES_PROJECT_ROOT="`cd ../examples/objc-ios; pwd`"

echo "Generate Documentation"
./build-appledoc.sh ../tests/objc-ios

echo "Build"

echo $?
pushd "$TESTS_PROJECT_ROOT"
xctool -workspace "$TESTS_PROJECT_ROOT/$TESTS_PROJECT_NAME.xcworkspace" -scheme $TESTS_PROJECT_NAME -sdk iphonesimulator build test
popd

# somehow, clean on example project seems to fail...
pushd "$EXAMPLES_PROJECT_ROOT"
xctool -workspace "$EXAMPLES_PROJECT_ROOT/$EXAMPLES_PROJECT_NAME.xcworkspace" -scheme $EXAMPLES_PROJECT_NAME -sdk iphonesimulator build test
popd

echo "Validate PodSpec"
cd ..
pod --version
pod spec lint Transit.podspec