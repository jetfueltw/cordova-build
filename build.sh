#! /bin/bash
source env.sh
rm -rf $REPOSITORY_NAME
docker build -t jetfueltw/cordova:latest .