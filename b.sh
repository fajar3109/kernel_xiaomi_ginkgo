SECONDS=0 # builtin bash timer
ZIPNAME="simplekernel-r-4.14.262-ginkgo-$(date '+%Y%m%d-%H%M').zip"
SDC_DIR="/workspace/Gitpod-Workspaces/sdc-clang"
GCC_DIR="/workspace/Gitpod-Workspaces/gccZ"
GCC64_DIR="/workspace/Gitpod-Workspaces/gcc64Z"
AK3_DIR="$HOME/android/AnyKernel3"
DEFCONFIG="vendor/ginkgo-perf_defconfig"

export PATH="${SDC_DIR}/compiler/bin:${GCC64_DIR}/bin:${GCC_DIR}/bin:/usr/bin:${PATH}"

if ! [ -d "$SDC_DIR" ]; then
echo "SnapDragon clang not found! Cloning to $SDC_DIR..."
if ! git clone -b master --depth=1 https://github.com/ThankYouMario/proprietary_vendor_qcom_sdclang -b 14 $SDC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC64_DIR" ]; then
echo "GCC 64 not found! Cloning to $GCC64_DIR..."
if ! git clone https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 12 --depth=1 $GCC64_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "$GCC_DIR" ]; then
echo "GCC not found! Cloning to $GCC_DIR..."
if ! git clone https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 12  --depth=1 $GCC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

export KBUILD_BUILD_USER=fajar
export KBUILD_BUILD_HOST=gitpod

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
make -j$(nproc --all) O=out ARCH=arm64 LD_LIBRARY_PATH="${GC_DIR}/lib:${LD_LIBRARY_PATH}" CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-zyc-linux-gnu- CROSS_COMPILE_ARM32=arm-zyc-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img

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