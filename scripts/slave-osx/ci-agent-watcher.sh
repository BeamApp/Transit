#!/bin/bash

~/scripts/ci-agent-watcher.py || launchctl stop com.getbeamapp.ci.agent
