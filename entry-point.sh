#!/bin/sh
set -xeo
env
echo $@

cd /usr/local/app
node index.js