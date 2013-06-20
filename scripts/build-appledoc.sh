#!/bin/sh
set -e

if [ "$1" ] 
then
  cd "$1"
fi

/usr/local/bin/appledoc --project-name Transit --project-company "BeamApp UG" --company-id com.beamapp --output ./documentation --no-create-docset --no-repeat-first-par --logformat xcode --warn-undocumented-member --warn-empty-description --warn-undocumented-object --keep-undocumented-members --keep-undocumented-objects --verbose 4 ../../source/objc/Transit.h