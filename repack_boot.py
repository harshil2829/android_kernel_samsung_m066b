#!/usr/bin/env python3
import struct, os, sys

def make_boot_img(kernel_path, out_boot_path):
    if not os.path.exists(kernel_path):
        print(f"[!] Error: Kernel not found at {kernel_path}")
        sys.exit(1)

    with open(kernel_path, 'rb') as f:
        kernel_data = f.read()

    kernel_size = len(kernel_data)
    header = bytearray(4096)
    
    # Android Boot Image Header Version 4
    # Magic
    header[0:8] = b'ANDROID!'
    # kernel_size (uint32 at offset 8)
    struct.pack_into('<I', header, 8, kernel_size)
    # ramdisk_size = 0 (uint32 at offset 12)
    struct.pack_into('<I', header, 12, 0)
    # os_version = 0x1a000199 (uint32 at offset 16)
    struct.pack_into('<I', header, 16, 0x1a000199)
    # header_size = 1584 (uint32 at offset 20)
    struct.pack_into('<I', header, 20, 1584)
    # header_version = 4 (uint32 at offset 40)
    struct.pack_into('<I', header, 40, 4)

    PAGE_SIZE = 4096
    TOTAL_SIZE = 67108864 # 64MB GKI boot partition

    os.makedirs(os.path.dirname(os.path.abspath(out_boot_path)), exist_ok=True)
    with open(out_boot_path, 'wb') as f:
        f.write(header)
        f.write(kernel_data)
        kernel_pad = (PAGE_SIZE - (kernel_size % PAGE_SIZE)) % PAGE_SIZE
        f.write(b'\x00' * kernel_pad)
        current_pos = f.tell()
        if current_pos < TOTAL_SIZE:
            f.write(b'\x00' * (TOTAL_SIZE - current_pos))

    print(f"[✔] Created {out_boot_path} (Header v4, Kernel size: {kernel_size} bytes, Total size: {TOTAL_SIZE} bytes)")

if __name__ == '__main__':
    kernel = sys.argv[1] if len(sys.argv) > 1 else 'build/Image.gz'
    out_boot = sys.argv[2] if len(sys.argv) > 2 else 'build/boot.img'
    make_boot_img(kernel, out_boot)
