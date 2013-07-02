#!/bin/sh

set -e


TESTS_PROJECT_NAME="TransitTestsOSX"
TESTS_PROJECT_ROOT="`cd ../tests/objc-osx; pwd`"

EXAMPLES_PROJECT_NAME="TransitExampleOSX"
EXAMPLES_PROJECT_ROOT="`cd ../examples/objc-osx; pwd`"

xctool -workspace "$TESTS_PROJECT_ROOT/$TESTS_PROJECT_NAME.xcworkspace" -scheme $TESTS_PROJECT_NAME build test

cd "$EXAMPLES_PROJECT_ROOT"
xctool -workspace "$EXAMPLES_PROJECT_ROOT/$EXAMPLES_PROJECT_NAME.xcworkspace" -scheme $EXAMPLES_PROJECT_NAME build test
