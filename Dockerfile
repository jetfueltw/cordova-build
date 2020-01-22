FROM beevelop/cordova:latest
RUN apt-get update && apt-get install -yqq git vim zipalign libpng-dev libpng16-16 libxml2-dev pkg-config ninja-build cmake
WORKDIR /tmp/tools
RUN echo y | /opt/android/tools/bin/sdkmanager "platform-tools" "build-tools;28.0.3" "platforms;android-28"
RUN git clone --depth=1 https://github.com/facebook/xcbuild && cd xcbuild && git submodule update --init && make
ENV PATH=/tmp/tools/xcbuild/build:$PATH
WORKDIR /workspace
ADD utils/build-app.sh /tmp/shell/build-app.sh
EXPOSE 3000
VOLUME /workspace