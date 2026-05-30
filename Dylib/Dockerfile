FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SDK_VERSION=17.0
ENV MIN_VERSION=14.0

RUN apt-get update && apt-get install -y \
    clang \
    ldid \
    git \
    cmake \
    make \
    python3 \
    curl \
    xz-utils \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone https://github.com/tpoechtrager/cctools-port.git
WORKDIR /opt/cctools-port/cctools
RUN ./configure --prefix=/opt/cctools --with-llvm-config=/usr/bin/llvm-config --target=arm64-apple-darwin
RUN make -j$(nproc)
RUN make install

RUN git clone https://github.com/xybp888/iOS-SDKs.git /opt/ios-sdks
ENV IOS_SDK=/opt/ios-sdks/iPhoneOS${SDK_VERSION}.sdk

WORKDIR /build

ENTRYPOINT ["/bin/bash", "-c"]
