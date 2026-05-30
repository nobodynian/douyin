#!/bin/bash

cd "$(dirname "$0")"

echo "[*] 构建 Docker 镜像..."
docker build -t douyin-dylib-builder .

echo "[*] 编译 dylib..."
docker run --rm -v "$(pwd):/build" douyin-dylib-builder "
    cd /build && \
    /opt/cctools/bin/clang \
        -target arm64-apple-ios14.0 \
        -isysroot /opt/ios-sdks/iPhoneOS17.0.sdk \
        -mios-version-min=14.0 \
        -dynamiclib \
        -fobjc-arc \
        -framework Foundation \
        -framework UIKit \
        -install_name @rpath/libDouyinMysteryUser.dylib \
        -o libDouyinMysteryUser.dylib \
        DouyinMysteryUser.m && \
    echo '[+] 编译成功！' && \
    ls -lh libDouyinMysteryUser.dylib
"

if [ -f "libDouyinMysteryUser.dylib" ]; then
    echo "[+] 文件已生成: libDouyinMysteryUser.dylib"
else
    echo "[-] 编译失败"
fi
