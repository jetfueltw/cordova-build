#! /bin/bash

# ./build-app.sh android <projectBasePath>    產出android app

platform=$1
platform=$(printf '%s\n' "$platform" | awk '{ print tolower($0) }')

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
echo "ANDROID_RELEASE_APK_OUTPUT_PATH: $ANDROID_RELEASE_APK_OUTPUT_PATH"
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

    #latest version path
    latestVersionPath=${tmpOutputPath%\/*}/latest

    #build unsigned.apk
    echo Y | npm run build-android

    #get signed.apk
    echo $KEYSTORE_PASSWORD | jarsigner -verbose -keystore $KEYSTORE_FILE -signedjar $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_SIGNED_APK $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_UNSIGNED_APK $KEYSTORE_ALIAS

    #zipalign release.apk
    zipalign -v 4 $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_SIGNED_APK $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_RELEASE_APK

    #list outputs
    echo "list: $ANDROID_RELEASE_APK_OUTPUT_PATH" && ls -la $ANDROID_RELEASE_APK_OUTPUT_PATH

    #copy apk to tmpOutputPath
    mkdir -p $tmpOutputPath
    cp $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_RELEASE_APK $tmpOutputPath/$ANDROID_RELEASE_APK
    echo "list: $tmpOutputPath" && ls -la $tmpOutputPath

    #copy apk to latestVersionPath
    mkdir -p $latestVersionPath
    cp $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_RELEASE_APK $latestVersionPath/$ANDROID_RELEASE_APK
    echo "list: $latestVersionPath" && ls -la $latestVersionPath

    if [[ ! $(ls -A "$latestVersionPath/$ANDROID_RELEASE_APK" ) ]]; then
      echo "Build Failed"
      exit 2
    fi
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

  if [ $platform == "ios" ]; then
      buildIOSApp "ios/$tmpOutputPath"
  elif [ $platform == "android" ]; then
      buildAndroidApk "android/$tmpOutputPath"
  fi
}

readEnvList() {
  for ((i=0; i < ${#ENV_LIST[@]}; i++)); do
      THIS_ENV=${ENV_LIST[$i]}

      #change api url setting
      if [[ $THIS_ENV == "dev" ]] && [[ $ENV_DEV != "" ]]; then
          printf "use ENV_DEV for .env.production.local\n"
          printf $ENV_DEV | base64 -d > .env.production.local
      elif [[ $THIS_ENV == "qa" ]] && [[ $ENV_QA != "" ]]; then
          printf "use ENV_QA for .env.production.local\n"
          printf $ENV_QA | base64 -d > .env.production.local
      elif [[ $THIS_ENV == "prod" ]] && [[ $ENV_PROD != "" ]]; then
          printf "use ENV_PROD for .env.production.local\n"
          printf $ENV_PROD | base64 -d > .env.production.local
      else
        echo "Err! can not get ENV variable (ENV_DEV, ENV_QA, ENV_PROD) in CI for .env.production.local"
        exit 2
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
    printf "Build App - [platform]: $platform, [ENV]: $THIS_ENV, [AGENT]: $THIS_AGENT, [VERSION]: $THIS_VERSION\n"

    if [ $THIS_VERSION != "latest" ]; then
      printf "Set VERSION = $THIS_VERSION\n"
      printf "\nVERSION=$THIS_VERSION" >> .env.production.local
    fi

    printf "cat .env.production.local\n" && cat .env.production.local
    printf "cat .env.production.android.local\n" && cat .env.production.android.local
    buildApp $THIS_ENV/$THIS_AGENT/$THIS_VERSION
  done
}

#install node_modules
npm install --unsafe-perm
npm rebuild node-sass

#start to build app
readEnvList