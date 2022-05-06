#!/bin/sh

# Option on whether to upload the produced build to a file hosting service [Useful for CI builds]
UPLD=1
	if [ $UPLD = 1 ]; then
		UPLD_PROV="https://oshi.at"
        UPLD_PROV2="https://transfer.sh"
	fi

# Clone toolchain from its repository
git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang.git azure-clang

# Clone AnyKernel3
git clone --depth=1 https://github.com/100Daisy/AnyKernel3 -b guamp

# Export the PATH variable
export PATH="$(pwd)/azure-clang/bin:$PATH"

# Clean up out
find out -delete
mkdir out

# Compile the kernel
build_clang() {
    make -j"$(nproc --all)" \
    ARCH="arm64" \
    O=out \
    CC="ccache clang" \
    CXX="ccache clang++" \
    AR="ccache llvm-ar" \
    AS="ccache llvm-as" \
    NM="ccache llvm-nm" \
    LD="ccache ld.lld" \
    STRIP="ccache llvm-strip" \
    OBJCOPY="ccache llvm-objcopy" \
    OBJDUMP="ccache llvm-objdump"\
    OBJSIZE="ccache llvm-size" \
    READELF="ccache llvm-readelf" \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

make vendor/guamp_defconfig ARCH=arm64 O=out CC=clang
build_clang

# Zip up the kernel
zip_kernelimage() {
    rm -rf AnyKernel3/Image.gz-dtb
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
    rm -rf AnyKernel3/*.zip
    BUILD_TIME=$(date +"%d%m%Y-%H%M")
    cd AnyKernel3
    KERNEL_NAME=guampstock-"${BUILD_TIME}"
    zip -r9 "$KERNEL_NAME".zip ./*
    cd ..
}

FILE="$(pwd)/out/arch/arm64/boot/Image.gz-dtb"
if [ -f "$FILE" ]; then
    zip_kernelimage
    KERN_FINAL="$(pwd)/AnyKernel3/"$KERNEL_NAME".zip"
    echo "The kernel has successfully been compiled and can be found in $KERN_FINAL"
    if [ "$UPLD" = 1 ]; then
        for i in "$UPLD_PROV" "$UPLD_PROV2"; do
            curl --connect-timeout 5 -T "$KERN_FINAL" "$i"
            echo " "
        done
    fi
else
    echo "The kernel has failed to compile. Please check the terminal output for further details."
    exit 1
fi
