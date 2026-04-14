#!/bin/bash
#
# Copyright 2024 Gaël PORTAY
#           2024 Rtone
#
# SPDX-License-Identifier: LGPL-2.1-only
#

set -Eeuxo pipefail
trap 'rc=$?; echo "HOOK FAILED: rc=$rc at line $LINENO: $BASH_COMMAND" >&2' ERR

echo "arg=$1" >&2
echo "RAUC_SLOT_MOUNT_POINT=$RAUC_SLOT_MOUNT_POINT" >&2
echo "RAUC_SLOT_DEVICE=$RAUC_SLOT_DEVICE" >&2
echo "RAUC_SLOT_BOOTNAME=$RAUC_SLOT_BOOTNAME" >&2
echo "RUNTIME_DIRECTORY=$RUNTIME_DIRECTORY" >&2
ls -la "$RAUC_SLOT_MOUNT_POINT" >&2 || true

slot_pre_install() {
    echo "root=$RAUC_SLOT_DEVICE rauc.slot=$RAUC_SLOT_BOOTNAME console=tty1 console=serial0" >"$RUNTIME_DIRECTORY/cmdline.txt"
}

slot_post_install() {
    cp "$RUNTIME_DIRECTORY/cmdline.txt" "$RAUC_SLOT_MOUNT_POINT/cmdline.txt.tmp"
    mv "$RAUC_SLOT_MOUNT_POINT/cmdline.txt"{.tmp,}
    rm -f "$RAUC_SLOT_MOUNT_POINT/cmdline.txt.tmp"
}

if [ "$1" = "slot-pre-install" ]; then
    shift
    slot_pre_install "$@"
elif [ "$1" = "slot-post-install" ]; then
    shift
    slot_post_install "$@"
fi