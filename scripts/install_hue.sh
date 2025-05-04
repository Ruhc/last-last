#!/bin/bash
# Установка Hue для Ubuntu 20.04/22.04

sudo apt-get update
sudo apt-get install -y python3-dev python3-pip python3-venv git gcc g++ libsasl2-dev libldap2-dev libssl-dev libmysqlclient-dev libkrb5-dev
if [ ! -d hue ]; then
  git clone https://github.com/cloudera/hue.git
fi
cd hue
make apps
build/env/bin/hue runserver 0.0.0.0:8888 