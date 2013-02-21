#!/bin/sh

set -e

BUILD_NUMBER=$1
ROOT=$(cd ..; pwd)

die()
{
    echo >&2 "$@"
    exit
}

[ "$#" -ge 1  ] || die "Usage: $0 BUILD_NUMBER"

stop_emulator()
{
  echo "Stopping emulator (if exists)"
  adb emu kill || echo "Failed to stop emulator"
}

ensure_emulator()
{
  echo "Ensure that emulator is running..."

  adb start-server
  device=$(android list avd -c)

  echo "Booting AVD $device..."
  emulator -avd $device &

  echo "Waiting until device has booted..."
  # adb wait-for-device hangs
  while [`adb shell 'getprop dev.bootcomplete'` != 1]; do
    puts "Waiting..."
    sleep 1
  done
  echo "Waiting until device has booted [DONE]"

  echo "Ensure that emulator is running [DONE]"
}

fill_local_properties()
{
    echo "Filling local.properties..."

    test -e "$ANDROID_HOME" || die "cannot find android SDK. Make sure, at ANDROID_HOME is set correctly."
    export PATH="$ANDROID_HOME/platform-tools:$PATH"

    # overwrite local.properties files
    echo "sdk.dir=$ANDROID_HOME" > source/java-android/local.properties
    echo "sdk.dir=$ANDROID_HOME" > tests/android/app/local.properties
    echo "sdk.dir=$ANDROID_HOME" > tests/android/tests/local.properties
    echo "sdk.dir=$ANDROID_HOME" > benchmark/cordova_android/local.properties
}

run_tests()
{
  echo "Building java-android..."

  fill_local_properties

  pushd `pwd`
  cd source/java-android
  ant clean debug
  popd

  echo "Building java-android... [DONE]"

  echo "Building test app and run tests..."

  pushd `pwd`
  cd tests/android/tests

  adb wait-for-device
  ant emma debug
# deactivate tests for now
#  ant emma installt test
  popd

  echo "Building test app and run tests [DONE]"
}

pushd `pwd`
cd $ROOT
# stop_emulator
# ensure_emulator
run_tests
popd
