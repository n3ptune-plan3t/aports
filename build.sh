#!/bin/sh
set -e

apk update
apk add alpine-sdk abuild-rootbld bubblewrap sudo

adduser -D builder
addgroup builder abuild
chown -R builder /repo
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder

su builder -c 'abuild-keygen -a -i -n </dev/null'

export APORTSDIR=/repo
export REPODEST=/repo/out
cd /repo

found=0
for apkbuild in $(find . -maxdepth 2 -name APKBUILD); do
  found=1
  d=$(dirname "$apkbuild")
  echo "==> Building $d"
  ( cd "$d" && su builder -c "abuild checksum && abuild rootbld" )
done

if [ "$found" -eq 0 ]; then
  echo "No APKBUILD files found under $APORTSDIR" >&2
  exit 1
fi

echo "==> Build complete. Packages in $REPODEST"
find "$REPODEST" -name '*.apk'
