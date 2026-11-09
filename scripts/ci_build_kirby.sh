#!/bin/bash
set -euo pipefail

echo "=== 1. Configure Xcode 16 ==="
if [ -d /Applications/Xcode_16.2.app ]; then
  sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer
elif [ -d /Applications/Xcode_16.1.app ]; then
  sudo xcode-select -s /Applications/Xcode_16.1.app/Contents/Developer
elif [ -d /Applications/Xcode_16.0.app ]; then
  sudo xcode-select -s /Applications/Xcode_16.0.app/Contents/Developer
elif [ -d /Applications/Xcode_16.app ]; then
  sudo xcode-select -s /Applications/Xcode_16.app/Contents/Developer
fi
xcodebuild -version
xcrun -sdk iphoneos metal --version

echo "=== 2. Install .NET 10 Runtime ==="
curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 10.0 || true
if ! command -v dotnet > /dev/null || ! dotnet --list-runtimes | grep -q "Microsoft.NETCore.App 10."; then
  echo "Installing via brew cask dotnet-sdk..."
  brew install --cask dotnet-sdk || true
fi
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
dotnet --info || true

echo "=== 3. Install Build Tools ==="
brew install xcodegen zstd
pip3 install --break-system-packages fonttools capstone lz4 pillow

echo "=== 4. Unpack Preprocessed Kirby Assets ==="
mkdir -p build/kirby_shpkg build/patched_v65536 build/kirby_marker/mov/EventMovie
tar -xzf build_inputs/kirby_shpkg.tar.gz -C build/kirby_shpkg
tar -xzf build_inputs/kirby_patched.tar.gz -C build/patched_v65536
touch build/kirby_marker/mov/EventMovie/Ending.webm

echo "=== 5. Update Tool Lock & Header ==="
python3 dm/gfx/tools/tool_lock.py --update-lock
python3 dm/gfx/tools/dmsh_chain.py --header
cat dm/gfx/tools/dmsh_chain.lock

echo "=== 6. Compile Metal Shaders (dmsh_build.py) ==="
export DM_GAME="01004D300C5AE000"
export IOSOUT="build/ios/dmsh_b"
export DMSH_TARGETS="ios"
export J="4"
python3 dm/gfx/tools/dmsh_build.py build/kirby_shpkg build/shcache

echo "=== 7. Build Native iOS IPA (build_ipa.sh) ==="
export GAME="01004D300C5AE000"
export W="$PWD/build/kirby-work"
export PATCHED="$PWD/build/patched_v65536"
export MSL_IOS="$PWD/build/ios/dmsh_b"
export DM_COPY_ROMFS="NO"
export ROMFS="$PWD/build/kirby_marker"
export DM_SHOW_FPS="1"
export DM_DISPLAY_NAME="Kirby and the Forgotten Land"
export DM_APP_VERSION="1.1.0"
export DM_BUNDLE_ID="org.nxnative.01004d300c5ae000"
export DM_ICON="$PWD/build_inputs/icon.jpg"
export CONTROL="$PWD/build_inputs/control.nacp"
bash dm/ios/tools/build_ipa.sh "$PWD/KirbyAndTheForgottenLand.ipa"

echo "=== 8. Verify Result ==="
ls -lh KirbyAndTheForgottenLand.ipa
echo "Done!"
