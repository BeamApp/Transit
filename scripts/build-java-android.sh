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

run_tests()
{
  echo "Building java-android..."

  pushd `pwd`
  cd source/java-android
  ant debug
  popd

  echo "Building java-android... [DONE]"

  echo "Building test app and run tests..."

  pushd `pwd`
  cd tests/android/tests

  adb wait-for-device
  ant emma debug
  ant emma installt test
  popd

  echo "Building test app and run tests [DONE]"
}

pushd `pwd`
cd $ROOT
# stop_emulator
# ensure_emulator
run_tests
popd
