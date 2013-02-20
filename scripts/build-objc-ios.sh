#!/bin/sh
# adapted from: https://coderwall.com/p/sskbow

set -e


BUILD_NUMBER=$1

die () {
    echo >&2 "$@"
    exit
}
[ "$#" -ge 1  ] || die "$0 BUILD_NUMBER"


PROJECT_NAME="TransitTestsIOS"
PROJECT_ROOT="`cd ../tests/objc-ios; pwd`"
SYMROOT="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"


echo "### CREATE DIST DIRECTORY"
echo "rm -rf $SYMROOT"
rm -rf "$SYMROOT"
echo "rm -rf $DIST_DIR"
rm -rf "$DIST_DIR"
echo "mkdir -p $DIST_DIR"
mkdir -p "$DIST_DIR"
ls -laF


build_and_package()
{
	OLD_DIR=`pwd`
    CONFIGURATION=$1
    PACKAGENAME=`echo $CONFIGURATION | sed 's%/%-%g' | tr '[A-Z]' '[a-z]'`
    BUILD_DIR="$SYMROOT/$PACKAGENAME-iphoneos"

    if [ "$MODIFYCONFIG" = "YES" ]; then
        replace_infoplist $CONFIGURATION
    fi

    echo "### EXECUTING BUILD COMMAND : CONFIGURATION[$CONFIGURATION]"
	echo "current dir `pwd`"
    echo "xcodebuild -workspace $PROJECT_ROOT/$PROJECT_NAME.xcworkspace -scheme $PROJECT-configuration $CONFIGURATION -sdk iphoneos CONFIGURATION_BUILD_DIR=\"$BUILD_DIR\" SYMROOT=$SYMROOT ARCHS=i386 clean build"
    xcodebuild -workspace $PROJECT_ROOT/$PROJECT_NAME.xcworkspace -scheme $PROJECT_NAME -configuration "$CONFIGURATION" -sdk iphoneos CONFIGURATION_BUILD_DIR="$BUILD_DIR" SYMROOT="$SYMROOT" ONLY_ACTIVE_ARCH=NO clean build

    BUILD_RESULT=$?

    ## HANDLE BUILD FAILURE
    if [ "$BUILD_RESULT" -ne "0" ]; then
        echo "### FAILED TO BUILD APP : CONFIGURATION[$CONFIGURATION] WITH EXIT CODE[$BUILD_RESULT]"
        exit $?
    fi

    echo ""
    echo "### START PACKAGING APP : CONFIGURATION[$CONFIGURATION]"
    echo ""

    # PACKAGE
    cd "$BUILD_DIR"
    zip -9 -y -r "$DIST_DIR/""$PROJECT_NAME""_$PACKAGENAME"_"b$BUILD_NUMBER.zip" "$PROJECT_NAME.app"

    if [ -f "$DIST_DIR/""$PROJECT_NAME""_$PACKAGENAME"_"b$BUILD_NUMBER.zip" ]; then
        echo ""
        echo "### FINISHED BUILD APP : CONFIGURATION[$CONFIGURATION]"
        echo "### " `date`
        echo ""
    else
        echo "PACKAGING FAILED : CONFIGURATION[$CONFIGURATION]"
        exit 1
    fi
	cd "$OLD_DIR"
}


kill_simulator()
{
    if [[ $(ps axo pid,command | grep "[i]Phone Simulator") ]]; then
        killall "iPhone Simulator"
    fi
}


run_integration_tests()
{
    echo "### RUN INTEGRATION TESTS"
    BUILD_DIR="$SYMROOT/Debug-iphonesimulator"
    xcodebuild -workspace "$PROJECT_NAME".xcworkspace -scheme "Integration Tests" -configuration Debug -sdk iphonesimulator -xcconfig="Pods/Pods-integration.xcconfig" CONFIGURATION_BUILD_DIR="$BUILD_DIR" SYMROOT="$SYMROOT" clean build

    kill_simulator

    OUTPUT_FILE="$DIST_DIR/kif_results_$BUILD_NUMBER.txt"
    ios-sim launch "$BUILD_DIR/""$PROJECT_NAME"" (Integration Tests).app" --stdout "$OUTPUT_FILE" --stderr "$OUTPUT_FILE"
    cat "$OUTPUT_FILE"
    grep -q "TESTING FINISHED: 0 failures" "$OUTPUT_FILE"
}


run_unit_tests()
{
    OUTPUT_FILE="$DIST_DIR/unittest_results_$BUILD_NUMBER.txt"

    echo "### RUN UNIT TESTS"
    kill_simulator
    xcodebuild -workspace "$PROJECT_ROOT/$PROJECT_NAME".xcworkspace/ -scheme "Jenkins Unit Tests" -sdk iphonesimulator TEST_AFTER_BUILD=YES ONLY_ACTIVE_ARCH=NO clean build RUN_UNIT_TEST_WITH_IOS_SIM=YES 2>&1 | ./ocunit2junit.rb
	kill_simulator
}


build_and_package Debug
build_and_package Release
#run_integration_tests
run_unit_tests