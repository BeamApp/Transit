#!/bin/sh

set -e


TESTS_PROJECT_NAME="TransitTestsOSX"
TESTS_PROJECT_ROOT="`cd ../tests/objc-osx; pwd`"

echo "Build"

xctool -workspace "$TESTS_PROJECT_ROOT/$TESTS_PROJECT_NAME.xcworkspace" -scheme $TESTS_PROJECT_NAME build test
