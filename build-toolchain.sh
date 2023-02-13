#!/usr/bin/env bash

# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

# Build LLVM
msg "Building LLVM..."
./build-llvm.py \
    --ref "release/16.x" \
    --vendor-string "STRIX" \
    --lto "full" \
    --pgo "kernel-defconfig" \
    --no-update \
    --no-ccache \
    --quiet-cmake \
    --shallow-clone \
    --targets ARM AArch64 X86

# Check if the final clang binary exists or not.
for file in install/bin/clang-1*
do
    if [ -e "$file" ]; then
        msg "LLVM building successful"
    else 
        err "LLVM build failed!"
        exit
    fi
done

# Build binutils
msg "Building binutils..."
./build-binutils.py --targets arm aarch64 x86_64

# Remove unused products
rm -fr install/include
rm -f install/lib/*.a install/lib/*.la

# Strip remaining products
for f in $(find install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
    strip -s "${f: : -1}"
done

# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
for bin in $(find install -mindepth 2 -maxdepth 3 -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}'); do
    # Remove last character from file output (':')
    bin="${bin: : -1}"

    echo "$bin"
    patchelf --set-rpath "$DIR/../lib" "$bin"
done
