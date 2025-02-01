#!/usr/bin/env bash

cd "$(realpath "$(dirname "$0")")" || exit
wget -O zapret.tar.gz https://github.com/bol-van/zapret/releases/download/v70/zapret-v70.tar.gz
tar -xvzf zapret.tar.gz
mv zapret*/* ./
rm -rf zapret*
sudo ./install_easy.sh << EOF
Y

Y



Y





EOF
