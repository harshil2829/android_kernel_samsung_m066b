#!/bin/bash
set -e

export RDIR="$(pwd)"
export ARCH=arm64
export OUT_DIR="${RDIR}/out"

if [ -d "${RDIR}/toolchain/clang-r450784e/bin" ]; then
    export CLANG_BIN="${RDIR}/toolchain/clang-r450784e/bin"
    export PATH="${CLANG_BIN}:${PATH}"
fi

export CROSS_COMPILE="aarch64-linux-gnu-"
export LLVM=1
export LLVM_IAS=1

export KERNEL_DIR="${RDIR}/kernel-5.15"
export MODULE_DIR="${RDIR}/memkernel"
export MODULE_DIR_ENH="${RDIR}/memkernel_enhanced"

# Function to package a .ko into a self-extracting .sh driver script
package_to_sh() {
    local ko_file="$1"
    local out_sh="$2"
    
    if [ ! -f "${ko_file}" ]; then
        return
    fi
    
cat << 'EOF' > "${out_sh}"
#!/system/bin/sh
# RT-Dev Driver Self-Extracting Loader for SM-M066B (Samsung Galaxy M06 5G)
# Kernel: 5.15.151 | MediaTek MT6835 (Dimensity 6100+)
# Made by: @rajput_harshil

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}       RT-Dev Kernel Driver for SM-M066B            ${NC}"
echo -e "${YELLOW}           Made by: @rajput_harshil                 ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo ""

if [ "$(id -u)" != "0" ]; then
  echo -e "${RED}[!] Error: Please run this script as root (su)${NC}" 1>&2
  exit 1
fi

TMP_MOD="/data/local/tmp/rt_driver.ko"
rm -f "${TMP_MOD}" 2>/dev/null

# Extract the embedded .ko payload
sed "1,/^#__PAYLOAD_START__$/d" "$0" > "${TMP_MOD}"
chmod 644 "${TMP_MOD}"

# Load the kernel module
echo -e "[+] Loading driver into kernel..."
if insmod "${TMP_MOD}"; then
  echo -e "${GREEN}[✔] Driver loaded successfully by @rajput_harshil!${NC}"
  echo -e "${GREEN}[✔] Device node is active and ready.${NC}"
  rm -f "${TMP_MOD}" 2>/dev/null
else
  rm -f "${TMP_MOD}" 2>/dev/null
  echo -e "${RED}[!] Driver load failed. Kernel log (dmesg):${NC}"
  dmesg | tail -n 20
  exit 1
fi
exit 0
#__PAYLOAD_START__
EOF
    cat "${ko_file}" >> "${out_sh}"
    chmod +x "${out_sh}"
    echo "[+] Generated self-extracting script: ${out_sh}"
}

JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

# Build memkernel
if [ -d "${MODULE_DIR}" ]; then
  echo "[+] Building memkernel module..."
  make -w \
    -C "${KERNEL_DIR}" \
    O="${OUT_DIR}" \
    M="${MODULE_DIR}" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE="${CROSS_COMPILE}" \
    -j"${JOBS}" \
    modules
fi

# Build memkernel_enhanced
if [ -d "${MODULE_DIR_ENH}" ]; then
  echo "[+] Building memkernel_enhanced module..."
  make -w \
    -C "${KERNEL_DIR}" \
    O="${OUT_DIR}" \
    M="${MODULE_DIR_ENH}" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE="${CROSS_COMPILE}" \
    -j"${JOBS}" \
    modules
fi

mkdir -p "${RDIR}/build/modules"
cp "${MODULE_DIR}"/*.ko "${RDIR}/build/modules/" 2>/dev/null || true
cp "${MODULE_DIR_ENH}"/*.ko "${RDIR}/build/modules/" 2>/dev/null || true

# Generate RT-Dev style .sh executable scripts
if [ -f "${RDIR}/build/modules/memkernel.ko" ]; then
    package_to_sh "${RDIR}/build/modules/memkernel.ko" "${RDIR}/build/modules/SM-M066B_memkernel.sh"
fi

if [ -f "${RDIR}/build/modules/memkernel_enhanced.ko" ]; then
    package_to_sh "${RDIR}/build/modules/memkernel_enhanced.ko" "${RDIR}/build/modules/SM-M066B_memkernel_enhanced.sh"
fi

echo "[+] External modules and .sh driver scripts built in build/modules/:"
ls -lh "${RDIR}/build/modules/"
