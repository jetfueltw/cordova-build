#! /bin/bash
docker tag jetfueltw/cordova:android-28 jetfueltw/cordova:latest
docker push jetfueltw/cordova:android-28
docker push jetfueltw/cordova:latest

docker tag jetfueltw/cordova:android-28 richguo0615dk/cordova:latest
docker push richguo0615dk/cordova:latest