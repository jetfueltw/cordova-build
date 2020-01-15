# docker-cordova
透過 cordova 建置/編譯 Android/IOS App</br>
主要用來 build Android apk</br>
IOS App 需要 mac 與 Xcode，因此暫時無法直接build。</br></br>

若要執行 ./run.sh，啟動一個container，請先建立 env.sh 檔案，並填入：

````
#! /bin/bash

#用來build app的docker image
BUILD_APP_IMAGE=jetfueltw/cordova-build

CURRENT_PATH=$(pwd)

REPOSITORY_URL=https://<repositoryUrl> #ex. gitlab.com/orgnization/appProject.git
REPOSITORY_NAME=<repositoryName>  #ex. appPoject

#container內的工作目錄，專案mount進去的主要目錄
BUILD_WORKDIR=/workspace

#android
KEYSTORE_PASSWORD=<password>                                        #keystore的密碼
KEYSTORE_FILE_SOURCE=<$CURRENT_PATH/android-release-key.keystore>   # 在本地的位置
KEYSTORE_FILE=/tmp/key/android-release-key.keystore                 # keystore檔案放到container裡面的位置
KEYSTORE_ALIAS=<keystore alias>

ANDROID_APK_OUTPUT_PATH=<ex. /workspace/src-cordova/platforms/android/app/build/outputs/apk/release>
ANDROID_UNSIGNED_APK=$ANDROID_APK_OUTPUT_PATH/app-release-unsigned.apk  #剛build好，尚未簽名的apk檔案位置
ANDROID_SIGNED_APK=$ANDROID_APK_OUTPUT_PATH/app-release-signed.apk      #簽名好的apk檔案位置
ANDROID_RELEASE_APK=$ANDROID_APK_OUTPUT_PATH/app-release.apk            #完成品
````
