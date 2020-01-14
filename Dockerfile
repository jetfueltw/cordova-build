FROM beevelop/cordova:latest
RUN apt-get update && apt-get install -yqq git vim
WORKDIR /workspace
RUN echo y | /opt/android/tools/bin/sdkmanager "platform-tools" "build-tools;28.0.3" "platforms;android-28"
EXPOSE 3000
VOLUME /workspace