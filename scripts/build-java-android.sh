#!/bin/sh

set -e

BUILD_NUMBER=$1
ROOT=$(cd ..; pwd)

die()
{
    echo >&2 "$@"
    exit
}

[ "$#" -ge 1  ] || die "$0 BUILD_NUMBER"

boot()
{
  adb start-server
  device=$(android list avd -c)
  emulator -avd $device

  # while [`adb shell 'getprop dev.bootcomplete'` != 1]; do
  #   sleep 1
  # done

  adb wait-for-device
}

run()
{
  pushd `pwd`
  cd source/java-android
  ant debug
  popd

  pushd `pwd`
  cd tests/android/tests
  ant emma debug install test
  popd
}

pushd `pwd`
cd $ROOT
run
popd
