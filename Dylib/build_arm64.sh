#!/bin/bash

SDK_VERSION="17.0"
MIN_VERSION="14.0"

SRC="DouyinMysteryUser.m"
OUTPUT="libDouyinMysteryUser.dylib"

echo "[*] 开始编译 dylib (arm64)..."

rm -f $OUTPUT

xcrun -sdk iphoneos clang \
    -arch arm64 \
    -isysroot $(xcrun -sdk iphoneos --show-sdk-path) \
    -mios-version-min=$MIN_VERSION \
    -dynamiclib \
    -fobjc-arc \
    -framework Foundation \
    -framework UIKit \
    -install_name @rpath/$OUTPUT \
    -o $OUTPUT \
    $SRC

if [ $? -ne 0 ]; then
    echo "[-] 编译失败"
    exit 1
fi

echo "[*] 签名..."
if command -v ldid &> /dev/null; then
    ldid -S $OUTPUT
    echo "[+] 使用 ldid 签名完成"
else
    echo "[!] 未找到 ldid，跳过签名，请使用巨魔或其他工具签名"
fi

echo "[+] 编译完成: $OUTPUT"
ls -lh $OUTPUT
