#!/bin/sh

set -e

BUILD_NUMBER=$1
ORIGINAL_PWD=`pwd`
ROOT=$(cd ..; pwd)

die()
{
    echo >&2 "$@"
    exit 1
}

[ "$#" -ge 1  ] || die "Usage: $0 BUILD_NUMBER"

killed()
{
  cd $ORIGINAL_PWD
  exit 1
}

trap killed SIGINT SIGTERM SIGKILL

ensure_command()
{
  type $@ >/dev/null 2>&1 || { echo >&2 "No such command: $@. Android (platform-)tools in PATH?"; exit 1; }
}

precheck()
{
  for cmd in android adb emulator ant
  do
    ensure_command $cmd
  done
}

stop_emulator()
{
  echo "Stopping emulator (if exists)"
  adb emu kill || echo "Failed to stop emulator"
}

ensure_emulator()
{
  if (ps aux | grep '[e]mulator64-\(arm\|x86\)'); then
    echo "Emulator seems to be running already."
    return
  fi

  echo "No emulator found. Starting one..."

  adb start-server
  device=$(android list avd -c | head -n 1)

  echo "Booting AVD $device..."
  emulator -avd $device -no-audio &

  echo "Waiting for AVD $device..."
  adb wait-for-device

  echo "Emulator ready!"
}

package_manager_not_available()
{
  if (adb shell pm path android &> /dev/null)
  then
    return 0
  else
    return 1
  fi
}

ensure_package_manager()
{
  timeoutInSeconds=60
  timeout=`date -v+${timeoutInSeconds}S +%s`

  printf "Waiting for Package Manager"

  while package_manager_not_available
  do
    sleep 2
    now=`date +%s`
    if [ "$now" -ge "$timeout" ]
    then
      echo " [TIMEOUT]"
      die "PackageManager didn't become available within $timeoutInSeconds seconds"
    fi

    printf "."
  done

  echo " [READY]"
}

fill_local_properties()
{
    echo "Filling local.properties..."

    if [[ -z "$ANDROID_SDK_ROOT" ]]; then
        export ANDROID_SDK_ROOT=/usr/local/opt/android-sdk
    fi

    test -e "$ANDROID_SDK_ROOT" || die "cannot find android SDK. Make sure, at ANDROID_SDK_ROOT is set correctly."
    export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"

    # overwrite local.properties files
    echo "sdk.dir=$ANDROID_SDK_ROOT" > source/java-android/local.properties
    echo "sdk.dir=$ANDROID_SDK_ROOT" > tests/android/app/local.properties
    echo "sdk.dir=$ANDROID_SDK_ROOT" > tests/android/tests/local.properties
    echo "sdk.dir=$ANDROID_SDK_ROOT" > benchmark/cordova_android/local.properties
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
  ant clean emma debug
  ant emma installt test fetch-report
  popd

  echo "Building test app and run tests [DONE]"
}

precheck
pushd `pwd`
cd $ROOT
stop_emulator
ensure_emulator
ensure_package_manager
run_tests
stop_emulator
popd
