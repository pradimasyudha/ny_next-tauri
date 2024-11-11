# 12.7-slim
FROM debian@sha256:36e591f228bb9b99348f584e83f16e012c33ba5cad44ef5981a1d7c0a93eca22
ARG ANDROID_BUILDTOOLS_VERSION=35.0.0 \
    ANDROID_NDK_VERSION=27.2.12479018 \
    ANDROID_PLATFORMS_VERSION=35 \
    BUN_VERSION=1.1.33 \
    CMDLINE_VERSION=11076708 \
    RUST_VERSION=1.82.0

ENV ANDROID_HOME=/home/nonroot/Android/sdk \
    NDK_HOME=/home/nonroot/Android/sdk/ndk/27.2.12479018 \
    PATH=/root/.bun/bin:/root/.cargo/bin:$PATH

RUN groupadd -g 10001 \
             -r nonroot \
    && useradd -m \
               -u 10000 \
               -g nonroot \
               -d /home/nonroot \
               -r nonroot

WORKDIR /home/nonroot

RUN apt-get update
RUN apt-get install -y build-essential \
                       clang \
                       curl \
                       file \
                       jq \
                       libarchive-tools \
                       libayatana-appindicator3-dev \
                       librsvg2-dev \
                       libssl-dev \
                       libwebkit2gtk-4.1-dev \
                       libxdo-dev \
                       lld \
                       llvm \
                       nsis \
                       openjdk-17-jdk \
                       rclone \
                       unzip \
                       wget

RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}" \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh -s -- --default-toolchain=${RUST_VERSION} -y \
    && cargo install --locked cargo-xwin \
    && rustup target add aarch64-linux-android \
                         armv7-linux-androideabi \
                         i686-linux-android \
                         x86_64-linux-android \
                         x86_64-pc-windows-msvc \
                         i686-pc-windows-msvc \
                         aarch64-pc-windows-msvc

ADD https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_VERSION}_latest.zip commandlinetools-linux.zip

RUN mkdir -p Android/sdk/cmdline-tools/latest \
    && bsdtar --strip-components=1 \
              -xf commandlinetools-linux.zip \
              -C ./Android/sdk/cmdline-tools/latest \
    && yes | ./Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses \
    && ./Android/sdk/cmdline-tools/latest/bin/sdkmanager "platform-tools" \
                                                         "platforms;android-${ANDROID_PLATFORMS_VERSION}" \
                                                         "build-tools;${ANDROID_BUILDTOOLS_VERSION}" \
                                                         "ndk;${ANDROID_NDK_VERSION}"