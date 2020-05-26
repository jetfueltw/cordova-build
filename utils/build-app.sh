#! /bin/bash

# ./build-app.sh android <projectBasePath>    產出android app

platform=$1
platform=$(printf '%s\n' "$platform" | awk '{ print tolower($0) }')

projectBasePath=$2

if [ -z $platform ]; then
    echo "<platform> is empty."
    exit 1
fi

if [ -z $projectBasePath ]; then
    echo "<projectBasePath> is empty."
    exit 1
fi

if [ -z $LIVE_MODE ]; then
  export LIVE_MODE=false
fi

#string to array
IFS=',' read -a ENV_LIST <<< "$ENV_LIST"
IFS=',' read -a AGENT_LIST <<< "$AGENT_LIST"
IFS=',' read -a VERSION_LIST <<< "$VERSION_LIST"

#print params
echo "platform: $platform"
echo "LIVE_MODE: $LIVE_MODE"
echo "ENV_LIST: ${ENV_LIST[*]}"
echo "VERSION_LIST: ${VERSION_LIST[*]}"

echo "DEV_AGENT_LIST: ${DEV_AGENT_LIST[*]}"
echo "QA_AGENT_LIST: ${QA_AGENT_LIST[*]}"
echo "PROD_AGENT_LIST: ${PROD_AGENT_LIST[*]}"

echo "projectBasePath: $projectBasePath"
echo "KEYSTORE_FILE: $KEYSTORE_FILE"

echo "ANDROID_RELEASE_APK_OUTPUT_PATH: $ANDROID_RELEASE_APK_OUTPUT_PATH"
echo "ANDROID_DEBUG_APK_OUTPUT_PATH: $ANDROID_DEBUG_APK_OUTPUT_PATH"

echo "ANDROID_DEBUG_APK: $ANDROID_DEBUG_APK"
echo "ANDROID_UNSIGNED_APK: $ANDROID_UNSIGNED_APK"
echo "ANDROID_SIGNED_APK: $ANDROID_SIGNED_APK"
echo "ANDROID_RELEASE_APK: $ANDROID_RELEASE_APK"

cd $projectBasePath

buildAndroidApk() {
    #clean build
    rm -rf $ANDROID_DEBUG_APK_OUTPUT_PATH
    rm -rf $ANDROID_RELEASE_APK_OUTPUT_PATH

    #tmp path for upload to s3
    tmpOutputPath=$1
    if [ -z "$tmpOutputPath" ]; then
        tmpOutputPath="undefined"
    fi

    #latest version path
    latestVersionPath=$(echo $tmpOutputPath | sed "s/$THIS_VERSION/latest/")
    echo "android apk - tmpOutputPath: $tmpOutputPath"
    echo "android apk - latestVersionPath: $latestVersionPath"
    mkdir -p $tmpOutputPath
    mkdir -p $latestVersionPath

    #build debug apk
    if [[ ! -z $ANDROID_DEBUG_APK_OUTPUT_PATH && ! -z $ANDROID_DEBUG_APK && $THIS_ENV != "prod" ]]; then
        echo Y | SITE_CODE=$THIS_AGENT LIVE_MODE=$LIVE_MODE npm run debug-android

        if [[ -f $ANDROID_DEBUG_APK_OUTPUT_PATH/$ANDROID_DEBUG_APK ]]; then
          #copy debug apk to tmpOutputPath & latestVersionPath
          cp $ANDROID_DEBUG_APK_OUTPUT_PATH/$ANDROID_DEBUG_APK $tmpOutputPath/$ANDROID_DEBUG_APK
          cp $ANDROID_DEBUG_APK_OUTPUT_PATH/$ANDROID_DEBUG_APK $latestVersionPath/$ANDROID_DEBUG_APK
        else
          echo "ENV: $THIS_ENV, SITE_CODE: $THIS_AGENT, can not find debug apk"
        fi
    fi

    #build unsigned.apk
    echo Y | SITE_CODE=$THIS_AGENT LIVE_MODE=$LIVE_MODE npm run build-android

    #get signed.apk
    echo $KEYSTORE_PASSWORD | jarsigner -verbose -keystore $KEYSTORE_FILE -signedjar $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_SIGNED_APK $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_UNSIGNED_APK $KEYSTORE_ALIAS

    #zipalign release.apk
    zipalign -v 4 $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_SIGNED_APK $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_RELEASE_APK

    #list outputs
    #app-release-unsigned.apk
    echo "list: $ANDROID_RELEASE_APK_OUTPUT_PATH" && ls -la $ANDROID_RELEASE_APK_OUTPUT_PATH

    #copy signed apk to tmpOutputPath
    cp $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_RELEASE_APK $tmpOutputPath/$ANDROID_RELEASE_APK
    echo "list: $tmpOutputPath" && ls -la $tmpOutputPath

    #copy signed apk to latestVersionPath
    cp $ANDROID_RELEASE_APK_OUTPUT_PATH/$ANDROID_RELEASE_APK $latestVersionPath/$ANDROID_RELEASE_APK
    echo "list: $latestVersionPath" && ls -la $latestVersionPath

    if [[ ! $(ls -A "$latestVersionPath/$ANDROID_RELEASE_APK" ) ]]; then
      echo "Build Failed"
      exit 1
    fi
}

buildApp() {
  #tmp path for upload to s3
  tmpOutputPath=$1

  if [ $platform == "android" ]; then
      buildAndroidApk "android/$tmpOutputPath"
  else
      echo "params [platform] must be android"
      exit 1
  fi
}

readEnvList() {
  for ((i=0; i < ${#ENV_LIST[@]}; i++)); do
      THIS_ENV=${ENV_LIST[$i]}

      #change api url setting
      if [[ $THIS_ENV == "dev" ]] && [[ $ENV_DEV != "" ]]; then
          printf "use ENV_DEV for .env.production.local\n"
          printf $ENV_DEV | base64 -d > .env.production.local
          printf $ENV_DEV | base64 -d > .env.production
          printf $ENV_DEV | base64 -d > .env
      elif [[ $THIS_ENV == "qa" ]] && [[ $ENV_QA != "" ]]; then
          printf "use ENV_QA for .env.production.local\n"
          printf $ENV_QA | base64 -d > .env.production.local
          printf $ENV_QA | base64 -d > .env.production
          printf $ENV_QA | base64 -d > .env
      elif [[ $THIS_ENV == "prod" ]] && [[ $ENV_PROD != "" ]]; then
          printf "use ENV_PROD for .env.production.local\n"
          printf $ENV_PROD | base64 -d > .env.production.local
          printf $ENV_PROD | base64 -d > .env.production
          printf $ENV_PROD | base64 -d > .env
      else
        echo "Err! can not get ENV variable (ENV_DEV, ENV_QA, ENV_PROD) in CI for .env.production.local"
      fi

      readAgentList $THIS_ENV
  done
}

readAgentList() {
  THIS_ENV=$1

  agentList=()

  #依據環境，取得相對應的agentList
  if [[ $THIS_ENV == "dev" ]]; then
      agentList=$DEV_AGENT_LIST
  elif [[ $THIS_ENV == "qa" ]]; then
      agentList=$QA_AGENT_LIST
  elif [[ $THIS_ENV == "prod" ]]; then
      agentList=$PROD_AGENT_LIST
  fi

  #agentList存在，才繼續打包app
  if [[ ! -z $agentList ]]; then
    echo "ENV: $THIS_ENV, AGENT_LIST: $agentList"
    for ((j=0; j < ${#agentList[@]}; j++)); do
      THIS_AGENT=${agentList[$j]}

      #change agent setting
      export SITE_CODE=$THIS_AGENT
      echo "SITE_CODE=$SITE_CODE" > .env.production.android.local
      echo "SITE_CODE=$SITE_CODE" > .env.production.android
      echo "SITE_CODE=$SITE_CODE" > .env.android.local
      echo "SITE_CODE=$SITE_CODE" > .env.android
      echo "SITE_CODE=$SITE_CODE" >> .env
      echo "SITE_CODE=$SITE_CODE" >> .env.production
      echo "SITE_CODE=$SITE_CODE" >> .env.production.local

      readVersionList $THIS_ENV $THIS_AGENT
    done

  else
    echo "ENV: $THIS_ENV, without AGENT_LIST. can not build app."
  fi
}

readVersionList() {
  THIS_ENV=$1
  THIS_AGENT=$2

  for ((k=0; k < ${#VERSION_LIST[@]}; k++)); do
    export THIS_VERSION=${VERSION_LIST[$k]}
    printf "Build App - [platform]: $platform, [ENV]: $THIS_ENV, [AGENT]: $THIS_AGENT, [VERSION]: $THIS_VERSION\n"

    if [ $THIS_VERSION != "latest" ]; then
      printf "Set VERSION = $THIS_VERSION\n"
      printf "\nVERSION=$THIS_VERSION" >> .env.production.local
    fi

    printf "cat .env.production.local\n" && cat .env.production.local
    printf "cat .env.production.android.local\n" && cat .env.production.android.local
    buildApp $THIS_ENV/$THIS_AGENT/app/cpw/$THIS_VERSION/$platform
  done
}

#if [[ ! -z $ANDROID_KEYSTORE ]]; then
#  echo "create android keystore! path: /tmp/key"
#  mkdir -p /tmp/key && echo $ANDROID_KEYSTORE | base64 -d > /tmp/key/cpw-android-release-key.keystore
#fi

#install node_modules
echo "install node_modules ..."
npm install --unsafe-perm
npm rebuild node-sass

#start to build app
readEnvList

#check build success
if [[ -n ${ENV_LIST[dev]} && ! -z $DEV_AGENT_LIST  && ! -d android/dev ]]; then
  echo "ENV: dev - build failed!"
  exit 1
fi

if [[ -n ${ENV_LIST[qa]} && ! -z $QA_AGENT_LIST  && ! -d android/qa ]]; then
  echo "ENV: qa - build failed!"
  exit 1
fi

if [[ -n ${ENV_LIST[prod]} && ! -z $PROD_AGENT_LIST  && ! -d android/prod ]]; then
  echo "ENV: prod - build failed!"
  exit 1
fi