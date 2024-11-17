# docker buildx build -f Dockerfile -t nailyudha/tauri:2.0-2.1.0 -t nailyudha/tauri:latest --push --builder cloud-nailyudha-tauri --platform=linux/amd64,linux/arm64 .
# 12.7-slim
FROM debian@sha256:36e591f228bb9b99348f584e83f16e012c33ba5cad44ef5981a1d7c0a93eca22
ARG ANDROID_BUILDTOOLS_VERSION=35.0.0 \
    ANDROID_NDK_VERSION=27.2.12479018 \
    ANDROID_PLATFORMS_VERSION=35 \
    BUN_VERSION=1.1.33 \
    CMDLINE_VERSION=11076708 \
    JAVA_VERSION=21.0.5.11.1 \
    MISE_VERSION=2024.11.15\
    RCLONE_VERSION=1.68.2 \
    RUST_VERSION=1.82.0

ENV ANDROID_HOME=/root/Android/sdk \
    JAVA_HOME=/root/.local/share/mise/installs/java/corretto-${JAVA_VERSION} \
    NDK_HOME=/root/Android/sdk/ndk/${ANDROID_NDK_VERSION} \
    PATH=/root/.local/share/mise/shims:$PATH

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
                       libarchive-tools \
                       libayatana-appindicator3-dev \
                       librsvg2-dev \
                       libssl-dev \
                       libwebkit2gtk-4.1-dev \
                       libxdo-dev \
                       lld \
                       llvm \
                       nsis \
                       wget

RUN curl -L "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-$(dpkg --print-architecture | awk '{print ($1 == "amd64") ? "x64" : $1}')" -o /usr/local/bin/mise \
    && chmod +x /usr/local/bin/mise \
    && mise install -y bun@${BUN_VERSION} \
                       java@corretto-${JAVA_VERSION} \
                       rclone@${RCLONE_VERSION} \
                       rust@${RUST_VERSION} \
    && mise global bun@${BUN_VERSION} \
                   java@corretto-${JAVA_VERSION} \
                   rclone@${RCLONE_VERSION} \
                   rust@${RUST_VERSION} \
    && rustup default stable \
    && cargo install --locked cargo-xwin \
    && rustup target add aarch64-linux-android \
                         armv7-linux-androideabi \
                         i686-linux-android \
                         x86_64-linux-android \
                         x86_64-pc-windows-msvc \
                         i686-pc-windows-msvc \
                         aarch64-pc-windows-msvc

ADD https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_VERSION}_latest.zip cmdline.zip

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools/latest \
    && bsdtar --strip-components=1 \
              -xf cmdline.zip \
              -C ${ANDROID_HOME}/cmdline-tools/latest \
    && yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses \
    && ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platform-tools" \
                                                           "platforms;android-${ANDROID_PLATFORMS_VERSION}" \
                                                           "build-tools;${ANDROID_BUILDTOOLS_VERSION}" \
                                                           "ndk;${ANDROID_NDK_VERSION}" \
    && apt-get purge -y libarchive-tools \
    && apt-get autoremove -y \
                          --purge libarchive-tools \
    && apt-get clean -y \
    && rm -rf cmdline.zip