#!/bin/bash

SDK_VERSION="17.0"
MIN_VERSION="14.0"
ARCHS=("arm64" "arm64e")

SRC="DouyinMysteryUser.m"
OUTPUT="libDouyinMysteryUser.dylib"

echo "[*] 开始编译 dylib..."

rm -f $OUTPUT

for ARCH in "${ARCHS[@]}"; do
    echo "[*] 编译架构: $ARCH"
    
    xcrun -sdk iphoneos clang \
        -arch $ARCH \
        -isysroot $(xcrun -sdk iphoneos --show-sdk-path) \
        -mios-version-min=$MIN_VERSION \
        -dynamiclib \
        -fobjc-arc \
        -framework Foundation \
        -framework UIKit \
        -install_name @rpath/$OUTPUT \
        -o ${OUTPUT}_$ARCH \
        $SRC
    
    if [ $? -ne 0 ]; then
        echo "[-] 编译 $ARCH 失败"
        exit 1
    fi
done

echo "[*] 合并为通用二进制文件..."
lipo -create -output $OUTPUT ${OUTPUT}_arm64 ${OUTPUT}_arm64e

echo "[*] 清理临时文件..."
rm -f ${OUTPUT}_arm64 ${OUTPUT}_arm64e

echo "[*] 签名..."
ldid -S $OUTPUT

echo "[+] 编译完成: $OUTPUT"
ls -lh $OUTPUT
