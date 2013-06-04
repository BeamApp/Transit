#!/bin/sh

set -e

BUILD_NUMBER=$1

die () {
    echo >&2 "$@"
    exit
}
[ "$#" -ge 1  ] || die "$0 BUILD_NUMBER"


TESTS_PROJECT_NAME="TransitTestsIOS"
TESTS_PROJECT_ROOT="`cd ../tests/objc-ios; pwd`"

EXAMPLES_PROJECT_NAME="TransitExampleIOS"
EXAMPLES_PROJECT_ROOT="`cd ../examples/objc-ios; pwd`"

xctool -workspace "$TESTS_PROJECT_ROOT/$TESTS_PROJECT_NAME.xcworkspace" -scheme $TESTS_PROJECT_NAME build test

# somehow, clean on example project seems to fail...
xctool -workspace "$EXAMPLES_PROJECT_ROOT/$EXAMPLES_PROJECT_NAME.xcworkspace" -scheme $EXAMPLES_PROJECT_NAME  build test


echo "Validate PodSpec"
cd ..
pod spec lint