#!/usr/bin/env python
import urllib, socket
import xml.etree.ElementTree as ET

host_name = ".".join(socket.gethostname().split(".")[:-1])
url = "https://beamapp.ci.cloudbees.com/computer/api/xml?depth=1"

data = urllib.urlopen(url)
computerSet = ET.parse(data).getroot()

for computer in computerSet.iter("computer"):
    slave_name = computer.find("displayName").text
    if slave_name == host_name:
        exit(1)
