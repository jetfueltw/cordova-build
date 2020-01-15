#! /bin/bash

source env.sh
rm -rf $repositoryName
git clone $repositoryUrl
docker run -v $(pwd)/$repositoryName:/workspace --rm -it cordova-build bash