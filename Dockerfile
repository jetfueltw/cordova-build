FROM beevelop/cordova:latest
RUN apt-get update && apt-get install -yqq git vim zipalign
WORKDIR /tmp/tools
RUN echo y | /opt/android/tools/bin/sdkmanager "platform-tools" "build-tools;28.0.3" "platforms;android-28"
WORKDIR /workspace
ADD utils/build-android.sh /tmp/shell/build-android.sh
EXPOSE 3000
VOLUME /workspace