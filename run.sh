#! /bin/bash

source env.sh
git clone $repositoryUrl
docker run -v $(pwd)/$repositoryName:/workspace --rm -it cordova-build bash