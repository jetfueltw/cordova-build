#! /bin/bash

# ./build-app.sh android    產出android app
# ./build-app.sh ios        產出ios app

platform=$1
platform=$(printf '%s\n' "$platform" | awk '{ print toupper($0) }')

npm install --unsafe-perm

if [ $platform == "IOS" ]; then
    echo Y | npm run build-ios
elif [ $platform == "ANDROID" ]; then
    echo Y | npm run build-android
fi