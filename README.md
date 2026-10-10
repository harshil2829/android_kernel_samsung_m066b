# Samsung Galaxy M06 5G (SM-M066B) Kernel Source & Driver Modules

Official Samsung Open Source release for **Samsung Galaxy M06 5G (`SM-M066B`)**, tailored for Linux 5.15 GKI with automated GitHub Actions compilation and RT-Dev memory driver support.

## Device Specifications
- **Model**: Samsung Galaxy M06 5G (`SM-M066B`, Region SWA)
- **SoC**: MediaTek MT6835 (Dimensity 6100+)
- **Board / Codename**: `a06x`
- **Kernel Version**: Linux `5.15.151`
- **Compiler**: Official AOSP Clang `clang-r450784e` (LLVM 14.0.7)

## Building via GitHub Actions
1. Go to the **Actions** tab on GitHub.
2. Select **SM-M066B Kernel & Driver Compilation**.
3. Click **Run workflow**, enter your release tag (e.g. `v1.0`), and start the build.
4. Download the compiled `Image.gz` and driver packages (`SM-M066B_memkernel.sh` and `SM-M066B_memkernel_enhanced.sh`) from the GitHub Releases page.

## Included Modules
- `memkernel.ko` & `SM-M066B_memkernel.sh`: Memory read/write kernel driver loader.
- `memkernel_enhanced.ko` & `SM-M066B_memkernel_enhanced.sh`: Memory driver with hardware breakpoint (HWBP) monitoring support.
