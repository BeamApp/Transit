#!/bin/sh
# adapted from: https://coderwall.com/p/sskbow

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


build_and_package()
{
    CONFIGURATION=$1
    PROJECT_NAME=$2
    PROJECT_ROOT=$3

	pushd `pwd`

    SYMROOT="$PROJECT_ROOT/build"
    DIST_DIR="$PROJECT_ROOT/dist"

    PACKAGENAME=`echo $CONFIGURATION | sed 's%/%-%g' | tr '[A-Z]' '[a-z]'`
    BUILD_DIR="$SYMROOT/$PACKAGENAME-iphoneos"

    echo "### CREATE DIST DIRECTORY"
    echo "rm -rf $SYMROOT"
    rm -rf "$SYMROOT"
    echo "rm -rf $DIST_DIR"
    rm -rf "$DIST_DIR"
    echo "mkdir -p $DIST_DIR"
    mkdir -p "$DIST_DIR"
    ls -laF

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
	popd
}


kill_simulator()
{
    if [[ $(ps axo pid,command | grep "[i]Phone Simulator") ]]; then
        killall "iPhone Simulator"
    fi
}

run_unit_tests()
{
    PROJECT_NAME=$1
    PROJECT_ROOT=$2

    DIST_DIR="$PROJECT_ROOT/dist"


    OUTPUT_FILE="$DIST_DIR/unittest_results_$BUILD_NUMBER.txt"

    echo "### RUN UNIT TESTS"
    kill_simulator
    xcodebuild -workspace "$PROJECT_ROOT/$PROJECT_NAME".xcworkspace/ -scheme "Jenkins Unit Tests" -sdk iphonesimulator TEST_AFTER_BUILD=YES ONLY_ACTIVE_ARCH=NO clean build RUN_UNIT_TEST_WITH_IOS_SIM=YES 2>&1 | ./ocunit2junit.rb
	kill_simulator
}


build_and_package Debug $TESTS_PROJECT_NAME $TESTS_PROJECT_ROOT
build_and_package Release $TESTS_PROJECT_NAME $TESTS_PROJECT_ROOT
run_unit_tests $TESTS_PROJECT_NAME $TESTS_PROJECT_ROOT

build_and_package Debug $EXAMPLES_PROJECT_NAME $EXAMPLES_PROJECT_ROOT