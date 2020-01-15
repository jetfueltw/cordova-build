# docker-cordova
透過 cordova 建置/編譯 Android/IOS App</br>
主要用來 build Android apk</br>
IOS App 需要 mac 與 Xcode，因此暫時無法直接build。</br></br>

若要執行 ./run.sh，啟動一個container，請先建立 env.sh 檔案，並填入：

````
#! /bin/bash
repositoryUrl=https://[repositoryUrl] ex. gitlab.com/orgnization/appProject.git
repositoryName=[repositoryName]  ex. appPoject
````
