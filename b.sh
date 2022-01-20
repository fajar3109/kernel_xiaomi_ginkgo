SECONDS=0 # builtin bash timer
ZIPNAME="simplekernel-R-4.14.262-ginkgo-DTC-$(date '+%Y%m%d-%H%M').zip"
DTC_DIR="/workspace/Gitpod-Workspaces/dragontc-clang"
GCC_DIR="/workspace/Gitpod-Workspaces/gcc"
GCC64_DIR="/workspace/Gitpod-Workspaces/gcc64"
AK3_DIR="/workspace/Gitpod-Workspaces/AnyKernel3"
DEFCONFIG="vendor/ginkgo-perf_defconfig"

export PATH="${DTC_DIR}/bin:${GCC64_DIR}/bin:${GCC_DIR}/bin:/usr/bin:${PATH}"

if ! [ -d "$DTC_DIR" ]; then
echo "DTC clang not found! Cloning to $DTC_DIR..."
if ! git clone https://github.com/NusantaraDevs/DragonTC -b daily/10.0 --depth=1 $DTC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC64_DIR" ]; then
echo "GCC 64 not found! Cloning to $GCC64_DIR..."
if ! git clone https://github.com/wulan17/linaro_aarch64-linux-gnu-7.5 -b master --depth=1 $GCC64_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC_DIR" ]; then
echo "GCC not found! Cloning to $GCC_DIR..."
if ! git clone https://github.com/wulan17/linaro_arm-linux-gnueabihf-7.5 -b master --depth=1 $GCC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

export KBUILD_BUILD_USER=fajar
export KBUILD_BUILD_HOST=gitpodworkspaces

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 LD_LIBRARY_PATH="${DTC_DIR}/lib:${LD_LIBRARY_PATH}" CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabihf- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone -q https://github.com/fajar3109/AnyKernel3; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout master &> /dev/null
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
if ! [[ $HOSTNAME = "gitpod" && $USER = "fajar" ]]; then
curl -T $ZIPNAME temp.sh; echo
fi
else
echo -e "\nCompilation failed!"
exit 1
fi