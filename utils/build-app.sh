#! /bin/bash

# ./build-app.sh android <projectBasePath>    產出android app
# ./build-app.sh ios     <projectBasePath>    產出ios app

platform=$1
platform=$(printf '%s\n' "$platform" | awk '{ print toupper($0) }')

projectBasePath=$2

if [ -z $platform ]; then
    echo "<platform> is empty."
    exit 2
fi

if [ -z $projectBasePath ]; then
    echo "<projectBasePath> is empty."
    exit 2
fi

#print params
echo "platform: $platform"
echo "projectBasePath: $projectBasePath"
echo "KEYSTORE_FILE: $KEYSTORE_FILE"
echo "ANDROID_APK_OUTPUT_PATH: $ANDROID_APK_OUTPUT_PATH"
echo "ANDROID_UNSIGNED_APK: $ANDROID_UNSIGNED_APK"
echo "ANDROID_SIGNED_APK: $ANDROID_SIGNED_APK"
echo "ANDROID_RELEASE_APK: $ANDROID_RELEASE_APK"

cd $projectBasePath

#install node_modules
npm install --unsafe-perm
npm rebuild node-sass

if [ $platform == "IOS" ]; then
    echo Y | npm run build-ios
elif [ $platform == "ANDROID" ]; then
    #build unsigned.apk
    echo Y | npm run build-android

    #get signed.apk
    echo $KEYSTORE_PASSWORD | jarsigner -verbose -keystore $KEYSTORE_FILE -signedjar $ANDROID_SIGNED_APK $ANDROID_UNSIGNED_APK $KEYSTORE_ALIAS
    
    #zipalign release.apk
    zipalign -v 4 $ANDROID_SIGNED_APK $ANDROID_RELEASE_APK

    #list outputs
    ls -la $ANDROID_APK_OUTPUT_PATH
fi