#!/bin/bash
#
# Copyright 2024 Gaël PORTAY
#           2024 Rtone
#
# SPDX-License-Identifier: LGPL-2.1-only
#

set -e

slot_pre_install() {
    old_cmdline="$(cat "$RAUC_SLOT_MOUNT_POINT/cmdline.txt")"
    new_cmdline="$(printf '%s\n' "$old_cmdline" | sed -E 's#(^| )root=[^ ]+# root='"$RAUC_SLOT_DEVICE"'#')"

    # If there was no root= entry, append one
    case "$new_cmdline" in
        *"root="*) ;;
        *) new_cmdline="$new_cmdline root=$RAUC_SLOT_DEVICE" ;;
    esac

    printf '%s\n' "$new_cmdline" >"$RUNTIME_DIRECTORY/cmdline.txt"
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