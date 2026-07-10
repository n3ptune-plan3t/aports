#!/bin/sh
set -e

if [ -z "$PKG" ]; then
  echo "PKG is not set — pass the package directory to build" >&2
  exit 1
fi

if [ ! -f "/repo/$PKG/APKBUILD" ]; then
  echo "No APKBUILD found at /repo/$PKG/APKBUILD" >&2
  exit 1
fi

apk update
apk add alpine-sdk abuild-rootbld bubblewrap sudo

adduser -D builder
addgroup builder abuild
chown -R builder /repo
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder

su builder -c 'abuild-keygen -a -i -n </dev/null'

cat > /repo/.rootbld-repositories <<'EOF'
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

export APORTSDIR=/repo
export REPODEST=/repo/out
cd "/repo/$PKG"

su builder -c "abuild checksum && abuild rootbld"

echo "==> Build complete. Packages in $REPODEST"
find "$REPODEST" -name '*.apk'#!/bin/sh
set -e

apk update
apk add alpine-sdk abuild-rootbld bubblewrap sudo

adduser -D builder
addgroup builder abuild
chown -R builder /repo
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder

su builder -c 'abuild-keygen -a -i -n </dev/null'

cat > /repo/.rootbld-repositories <<'EOF'
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

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
