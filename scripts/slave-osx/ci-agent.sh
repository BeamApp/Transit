#!/bin/bash

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin
cd /Users/cloudbees/cloudbees
bash <(curl -fsSL https://raw.github.com/BeamApp/Transit/master/scripts/cloudbees-slave-go.sh)
