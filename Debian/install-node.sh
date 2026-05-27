#!/bin/bash

# 删除旧版本的nodejs
apt remove --purge nodejs
apt autoremove
rm -rf /usr/local/bin/npm
rm -rf /usr/local/share/man/man1/node*
rm -rf /usr/local/lib/dtrace/node.d
rm -rf /etc/systemd/system/node*
rm -rf /etc/apt/sources.list.d/nodesource.list

# 安装nodejs
curl -fsSL https://deb.nodesource.com/setup_19.x | bash - &&\
apt-get install -y nodejs
