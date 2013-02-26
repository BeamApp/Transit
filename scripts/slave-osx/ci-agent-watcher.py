#!/usr/bin/env python

import sys, urllib, socket
import xml.etree.ElementTree as ET

host_name = ".".join(socket.gethostname().split(".")[:-1])
url = "https://beamapp.ci.cloudbees.com/computer/api/xml?depth=1"

sys.stdout.write("Checking if {} is listed on beamapp.ci.cloudbees.com... ".format(host_name))

try:
    data = urllib.urlopen(url)
    computerSet = ET.parse(data).getroot()

    for computer in computerSet.iter("computer"):
        slave_name = computer.find("displayName").text
        if slave_name == host_name:
            print "YES"
            exit(0)
except Exception, e:
  print "ERROR ({})".format(e)
  exit(0)

print "NO"
exit(1)
