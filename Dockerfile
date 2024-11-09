FROM --platform=linux/amd64 debian:12.7-slim
RUN groupadd -g 10001 \
             -r nonroot \
    && useradd -m \
               -u 10000 \
               -g nonroot \
               -d /home/nonroot \
               -r nonroot
WORKDIR /home/nonroot

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y build-essential \
                       clang \
                       curl \
                       file \
                       libayatana-appindicator3-dev \
                       librsvg2-dev \
                       libssl-dev \
                       libwebkit2gtk-4.1-dev \
                       libxdo-dev \
                       lld \
                       llvm \
                       nsis \
                       openjdk-17-jdk \
                       unzip \
                       wget

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh -s -- --default-toolchain=1.82.0 -y \
    && curl -fsSL https://bun.sh/install | bash -s "bun-v1.1.33"

ADD https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip commandlinetools-linux.zip

RUN mkdir -p ./Android/sdk/cmdline-tools \
    && unzip commandlinetools-linux.zip -d ./Android/sdk/cmdline-tools \
    && mv ./Android/sdk/cmdline-tools/cmdline-tools ./Android/sdk/cmdline-tools/latest \
    && yes | ./Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses \
    && ./Android/sdk/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0" "ndk;27.2.12479018"

ENV PATH=/root/.bun/bin:/home/nonroot/Android/sdk/cmdline-tools/latest/bin:/home/nonroot/Android/sdk/platform-tools:/root/.cargo/bin:$PATH \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64 \
    ANDROID_HOME=/home/nonroot/Android/sdk \
    ANDROID_SDK_ROOT=/home/nonroot/Android/sdk \
    NDK_HOME=/home/nonroot/Android/sdk/ndk/27.2.12479018 \
    CARGO_HOME=/root/.cargo \
    RUSTUP_HOME=/root/.rustup

RUN rustup target add aarch64-linux-android \
                      armv7-linux-androideabi \
                      i686-linux-android \
                      x86_64-linux-android \
                      x86_64-pc-windows-msvc \
                      i686-pc-windows-msvc \
                      aarch64-pc-windows-msvc \
    && cargo install --locked cargo-xwin

COPY ./package.json ./bun.lockb ./
RUN bun i --frozen-lockfile \
          --verbose

COPY . .
RUN rm -rf ./src-tauri/gen \
           ./src-tauri/target \
           ./src-tauri/scripts \
    && mkdir -p ./src-tauri/scripts \
    && touch ./src-tauri/scripts/postinstall.sh \
             ./src-tauri/scripts/preinstall.sh \
             ./src-tauri/scripts/preremove.sh \
             ./src-tauri/scripts/postremove.sh \
    && bun tauri android init \
    && bun tauri build \
    && bun tauri build --runner cargo-xwin \
                       --target x86_64-pc-windows-msvc