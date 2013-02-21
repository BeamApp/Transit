COMPUTER_NAME="`hostname -s`"
PRIVATE_KEY_FILE="cloudbee-slave"

java -jar jenkins-cli.jar -i cloudbees-slave -s https://beamapp.ci.cloudbees.com customer-managed-slave -fsroot ./root -executors 1 -labels xcode_4_5 -name $COMPUTER_NAME