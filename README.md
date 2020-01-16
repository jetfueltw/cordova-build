# docker-cordova
透過 cordova 建置/編譯 Android/IOS App</br>
主要用來 build Android apk</br>
IOS App 需要 mac 與 Xcode，因此暫時無法直接build。</br></br>
用途：透過cordova編譯出android/ios的app，特別適用 Vue Quasar 的專案。</br></br>

#### 如何使用
這邊介紹的使用方式流程為：
1. 建立好一個 shell 檔案 `cordova-build.sh`，用來先 git clone 您的Quasar專案，接著執行此 image 來編譯App
2. 而上述的 shell 檔案，會需要另一個放入 Build App 所需參數的 shell 檔案 `cordova-build-env.sh`
3. 最後執行 `cordova-build.sh` 即可編譯出App。
4. 當然您也可以略過 git clone 的方法，直接在您的 Quasar 專案下，建立 `cordova-build.sh` 與 `cordova-build-env.sh` 做編譯App的工作。

先建立一個 corodova-build.sh 的執行檔，範例：
````
#! /bin/bash

#引用設定好的參數 (稍後說明)
source cordova-build-env.sh

#載入 Quasar 專案
rm -rf $REPOSITORY_NAME
git clone $REPOSITORY_URL
cd $REPOSITORY_NAME

#執行 image 開始 build app，將專案mount進入主要工作目錄，餵入Build app所需參數，執行container內已建立好的 build-app.sh 即可開始編譯。
docker run -v $(pwd):$BUILD_WORKDIR \
         -v $KEYSTORE_FILE_SOURCE:$KEYSTORE_FILE \
         -e KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD \
         -e KEYSTORE_FILE=$KEYSTORE_FILE \
         -e KEYSTORE_ALIAS=$KEYSTORE_ALIAS \
         -e ANDROID_APK_OUTPUT_PATH=$ANDROID_APK_OUTPUT_PATH \
         -e ANDROID_UNSIGNED_APK=$ANDROID_UNSIGNED_APK \
         -e ANDROID_SIGNED_APK=$ANDROID_SIGNED_APK \
         -e ANDROID_RELEASE_APK=$ANDROID_RELEASE_APK \
         -e BUILD_WORKDIR=$BUILD_WORKDIR \
         --rm $BUILD_APP_IMAGE /tmp/shell/build-app.sh ANDROID $BUILD_WORKDIR
````

#### cordova-build-env.sh 範例
````
#! /bin/bash

#用來build app的docker image
BUILD_APP_IMAGE=jetfueltw/cordova:android-28

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

#### 說明
建立好 cordova-build.sh 與 cordova-build-env.sh 之後，直接執行 cordova-build.sh 執可開始編譯app。