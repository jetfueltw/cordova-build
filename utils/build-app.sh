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

#string to array
IFS=',' read -a ENV_LIST <<< "$ENV_LIST"
IFS=',' read -a AGENT_LIST <<< "$AGENT_LIST"
IFS=',' read -a VERSION_LIST <<< "$VERSION_LIST"

#print params
echo "platform: $platform"
echo "ENV_LIST: ${ENV_LIST[*]}"
echo "AGENT_LIST: ${AGENT_LIST[*]}"
echo "VERSION_LIST: ${VERSION_LIST[*]}"

echo "projectBasePath: $projectBasePath"
echo "KEYSTORE_FILE: $KEYSTORE_FILE"
echo "ANDROID_APK_OUTPUT_PATH: $ANDROID_APK_OUTPUT_PATH"
echo "ANDROID_UNSIGNED_APK: $ANDROID_UNSIGNED_APK"
echo "ANDROID_SIGNED_APK: $ANDROID_SIGNED_APK"
echo "ANDROID_RELEASE_APK: $ANDROID_RELEASE_APK"

cd $projectBasePath

buildAndroidApk() {
    #tmp path for upload to s3
    tmpOutputPath=$1
    if [ -z "$tmpOutputPath" ]; then
        tmpOutputPath="undefined"
    fi

    #build unsigned.apk
    echo Y | npm run build-android

    #get signed.apk
    echo $KEYSTORE_PASSWORD | jarsigner -verbose -keystore $KEYSTORE_FILE -signedjar $ANDROID_APK_OUTPUT_PATH/$ANDROID_SIGNED_APK $ANDROID_APK_OUTPUT_PATH/$ANDROID_UNSIGNED_APK $KEYSTORE_ALIAS

    #zipalign release.apk
    zipalign -v 4 $ANDROID_APK_OUTPUT_PATH/$ANDROID_SIGNED_APK $ANDROID_APK_OUTPUT_PATH/$ANDROID_RELEASE_APK

    #list outputs
    echo "list: $ANDROID_APK_OUTPUT_PATH" && ls -la $ANDROID_APK_OUTPUT_PATH

    #copy apk to tmpOutputPath
    mkdir -p $tmpOutputPath
    cp $ANDROID_APK_OUTPUT_PATH/$ANDROID_RELEASE_APK $tmpOutputPath/$ANDROID_RELEASE_APK
    echo "list: $tmpOutputPath" && ls -la $tmpOutputPath
}

buildIOSApp() {
  #tmp path for upload to s3
  tmpOutputPath=$1
  if [ -z "$tmpOutputPath" ]; then
      tmpOutputPath="undefined"
  fi

  echo Y | npm run build-ios
}

buildApp() {
  #tmp path for upload to s3
  tmpOutputPath=$1

  if [ $platform == "IOS" ]; then
      buildIOSApp "IOS/$tmpOutputPath"
  elif [ $platform == "ANDROID" ]; then
      buildAndroidApk "ANDROID/$tmpOutputPath"
  fi
}

readEnvList() {
  for ((i=0; i < ${#ENV_LIST[@]}; i++)); do
      THIS_ENV=${ENV_LIST[$i]}

      #change api url setting
      if [ $THIS_ENV == "qa" ]; then
          echo $ENV_QA | base64 -d > .env.production.local
      elif [ $THIS_ENV == "prod" ]; then
          echo $ENV_PROD | base64 -d > .env.production.local
      else
          echo $ENV_QA | base64 -d > .env.production.local
      fi

      readAgentList $THIS_ENV
  done
}

readAgentList() {
  THIS_ENV=$1

  for ((j=0; j < ${#AGENT_LIST[@]}; j++)); do
    THIS_AGENT=${AGENT_LIST[$j]}

    #change agent setting
    echo "SITE_CODE=$THIS_AGENT" > .env.production.android.local

    readVersionList $THIS_ENV $THIS_AGENT
  done
}

readVersionList() {
  THIS_ENV=$1
  THIS_AGENT=$2

  for ((k=0; k < ${#VERSION_LIST[@]}; k++)); do
    THIS_VERSION=${VERSION_LIST[$k]}
    echo "Build App - [platform]: $platform, [ENV]: $THIS_ENV, [AGENT]: $THIS_AGENT, [VERSION]: $THIS_VERSION"
    buildApp $THIS_ENV/$THIS_AGENT/$THIS_VERSION
  done
}

#install node_modules
npm install --unsafe-perm
npm rebuild node-sass

#start to build app
readEnvList