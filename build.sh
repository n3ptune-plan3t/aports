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

id builder >/dev/null 2>&1 || adduser -D builder
addgroup builder abuild 2>/dev/null || true

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
find "$REPODEST" -name '*.apk'
