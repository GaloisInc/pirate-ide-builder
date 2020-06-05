#!/bin/bash

export VSCODE_VERSION=1.45.1
export VSCODE_SOURCE_URL=https://github.com/microsoft/vscode/archive/"$VSCODE_VERSION".zip
export BUILDARCH=x64
export npm_config_arch="$BUILDARCH"
export npm_config_target_arch="$BUILDARCH"

if [ ! -d vscode ]; then
    curl -LO "${VSCODE_SOURCE_URL}" 
    unzip "$VSCODE_VERSION".zip
    mv "vscode-${VSCODE_VERSION}" vscode
fi

./prepare_vscode.sh

cd vscode || exit

cp ../../extensions/* extensions/

export NODE_ENV=production

yarn gulp compile-build
yarn gulp compile-extensions-build
yarn gulp minify-vscode

if [[ "$BUILD_TARGET" == "osx" ]]; then
  npm install --global create-dmg
  yarn gulp vscode-darwin-min
  cd ../VSCode-darwin
  create-dmg VSCodium.app ..

elif [[ "$BUILD_TARGET" == "win32" ]]; then
  cp LICENSE.txt LICENSE.rtf # windows build expects rtf license
  yarn gulp "vscode-win32-${BUILDARCH}-min"
  # yarn gulp "vscode-win32-${BUILDARCH}-code-helper"
  # yarn gulp "vscode-win32-${BUILDARCH}-inno-updater"
  # yarn gulp "vscode-win32-${BUILDARCH}-archive"
  # yarn gulp "vscode-win32-${BUILDARCH}-system-setup"
  # yarn gulp "vscode-win32-${BUILDARCH}-user-setup"
else # linux
  yarn gulp vscode-linux-${BUILDARCH}-min

  yarn gulp "vscode-linux-${BUILDARCH}-build-deb"
  if [[ "$BUILDARCH" == "x64" ]]; then
    yarn gulp "vscode-linux-${BUILDARCH}-build-rpm"
  fi
  . ../create_appimage.sh
fi

cd ..
