if [ ! -d `xcode-select -print-path` ]; then
  echo "Please install Xcode before proceeding."
  echo "Visit https://github.com/BeamApp/Transit/wiki/Setup-Build-Slave to learn more"
  exit 1;
fi

echo "This script will install various command line tools and create and Android AVD."

if [ ! type brew >/dev/null 2>&1 ]; then
  echo "If Homebrew is not installled, you will need to enter your password at the start."
  echo "After this, everything should run automatically."
  
  read -n 1 -s
fi

if [ ! -f __xcode_license ]; then
  echo "Also, to make sure, Xcode works correctly, this script will show its EULA first."
  echo ""
  echo "Press 'Q' and hit enter to close the Xcode EULA."

  read -n 1 -s

  xcodebuild -license
  touch __xcode_license
fi


ensure_command()
{
  if type $1 >/dev/null 2>&1; then
    echo "$2 available, nothing to do."
  else
    echo "#########"
    echo "INSTALL $2"
    echo "#########"
    eval $3
  fi

#  type $1 >/dev/null 2>&1 || { echo "##### $2"; eval $3; }
}

ensure_command brew "Homebrew" "ruby -e \"\$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)\""
ensure_command git "Git" "brew install git"
ensure_command node "node.js+npm" "brew install node"
ensure_command phantomjs "PhantomJS" "brew install phantomjs"
ensure_command ios-sim "ios-sim" "brew install ios-sim"
ensure_command android "Android-SDK" "brew install android-sdk"


if [ ! -f jenkins-cli.jar ]; then
  echo "## Download jenkins-cli.jar"
  curl -Lo jenkins-cli.jar https://jenkins.ci.cloudbees.com/jnlpJars/jenkins-cli.jar
fi

if [ ! -f run-cloudbees-slave.sh ]; then
  echo "## Download run-cloudbees-slave.sh"
  curl -Lo run-cloudbees-slave.sh https://raw.github.com/BeamApp/Transit/master/scripts/run-cloudbees-slave.sh && chmod +x run-cloudbees-slave.sh
fi

if [ ! -f __android_update_sdk ]; then
  echo "## Installing/updating needed android packages"
  android update sdk -u --filter platform-tools,android-17,system-image,extra-intel-Hardware_Accelerated_Execution_Manager
  touch __android_update_sdk
  echo "## If message 'No Java runtime present, requesting infall.' appears, install JAVA and try again."
fi

if [ ! -f __android_create_avd ]; then
  echo "## Creating Android AVD 'default' for tests"
  echo "no" | android -s create avd -n default -t android-17 -b x86
  touch __android_create_avd
  echo "## If message 'No Java runtime present, requesting infall.' appears, install JAVA and try again."
fi

if [ ! -f cloudbees-slave ]; then
  echo "## Create new pair of SSH Keys"
  ssh-keygen -t rsa -f cloudbees-slave -N ""
fi

echo "## Run cloudbees-slave"
echo "   1. If message 'No Java runtime present, requesting infall.' appears,"
echo "      install JAVA and try again."
echo "   2. If message 'Authentication failed. No private key accepted.' appears,"
echo "       make sure to send us your automatically generated public SSH Key by"
echo "       running 'cat cloudbees-slave.pub | pbcopy' and "
echo "       comment on https://github.com/BeamApp/Transit/issues/26 to do so"

./run-cloudbees-slave.sh
