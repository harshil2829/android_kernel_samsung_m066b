#!/bin/bash
set -e

export RDIR="$(pwd)"
export ARCH=arm64
export SUBARCH=arm64
export KERNEL_DIR="${RDIR}/kernel-5.15"
export OUT_DIR="${RDIR}/out"

mkdir -p "${OUT_DIR}"
mkdir -p "${RDIR}/build"

# Set up toolchain
if [ -d "${RDIR}/toolchain/clang-r450784e/bin" ]; then
    export CLANG_BIN="${RDIR}/toolchain/clang-r450784e/bin"
    export PATH="${CLANG_BIN}:${PATH}"
    export CC="${CLANG_BIN}/clang"
    export LD="${CLANG_BIN}/ld.lld"
fi

export CROSS_COMPILE="aarch64-linux-gnu-"
export LLVM=1
export LLVM_IAS=1

# Fix case-sensitivity collisions from macOS git commits
if [ -f "${RDIR}/fix_case_sensitivity.py" ]; then
    echo "[+] Restoring case-sensitive netfilter headers and sources..."
    python3 "${RDIR}/fix_case_sensitivity.py"
fi

echo "======================================================"
echo "  Merging Defconfigs for SM-M066B (Dimensity 6100+)   "
echo "======================================================"

cd "${KERNEL_DIR}"
bash scripts/kconfig/merge_config.sh -m -O "${OUT_DIR}" \
    arch/arm64/configs/gki_defconfig \
    arch/arm64/configs/a06x_00_defconfig \
    kernel/configs/entry_level.config

# Disable Samsung DEFEX to allow custom drivers and root
"${KERNEL_DIR}/scripts/config" --file "${OUT_DIR}/.config" -d SECURITY_DEFEX || true
"${KERNEL_DIR}/scripts/config" --file "${OUT_DIR}/.config" -d SECURITY_DEFEX_USER || true
"${KERNEL_DIR}/scripts/config" --file "${OUT_DIR}/.config" -d SECURITY_DEFEX_DTM || true

# Disable BTF and IKHEADERS (avoids missing tools/bpf/resolve_btfids in open-source tree)
"${KERNEL_DIR}/scripts/config" --file "${OUT_DIR}/.config" -d DEBUG_INFO_BTF || true
"${KERNEL_DIR}/scripts/config" --file "${OUT_DIR}/.config" -d DEBUG_INFO_BTF_MODULES || true
"${KERNEL_DIR}/scripts/config" --file "${OUT_DIR}/.config" -d IKHEADERS || true

# Use ThinLTO instead of Full LTO to prevent runner memory exhaustion
"${KERNEL_DIR}/scripts/config" --file "${OUT_DIR}/.config" -d LTO_CLANG_FULL || true
"${KERNEL_DIR}/scripts/config" --file "${OUT_DIR}/.config" -e LTO_CLANG_THIN || true

# Generate final .config
make -C "${KERNEL_DIR}" O="${OUT_DIR}" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE="${CROSS_COMPILE}" \
    olddefconfig

echo "======================================================"
echo "  Building Linux 5.15.151 Kernel Image                "
echo "======================================================"

JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

make -C "${KERNEL_DIR}" O="${OUT_DIR}" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE="${CROSS_COMPILE}" \
    -j"${JOBS}" \
    Image.gz

if [ -f "${OUT_DIR}/arch/arm64/boot/Image.gz" ]; then
    cp "${OUT_DIR}/arch/arm64/boot/Image.gz" "${RDIR}/build/Image.gz"
    echo "[✔] Kernel Image.gz built successfully: ${RDIR}/build/Image.gz"
fi

if [ -f "${OUT_DIR}/arch/arm64/boot/Image" ]; then
    cp "${OUT_DIR}/arch/arm64/boot/Image" "${RDIR}/build/Image"
fi

cd "${RDIR}"

# Build external memkernel & memkernel_enhanced modules
if [ -f "${RDIR}/build_external_module.sh" ]; then
    echo "======================================================"
    echo "  Building MemKernel & RT-Dev Driver Modules          "
    echo "======================================================"
    bash "${RDIR}/build_external_module.sh"
fi

echo -e "\n[✔] All Builds Completed Successfully!\n"
