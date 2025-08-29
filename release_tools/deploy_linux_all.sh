#!/bin/bash

sh ./build_linux.sh

cd $(dirname "$0")
sh ./create_linux_package.sh

cd $(dirname "$0")
sh ./create_linux_appimage.sh
