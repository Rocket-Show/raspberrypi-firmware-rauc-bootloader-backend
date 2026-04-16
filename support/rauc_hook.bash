#!/bin/sh
set -eu

partuuid_of() {
    uuid="$(blkid -c /dev/null -s PARTUUID -o value "$1" || true)"
    [ -n "$uuid" ] || {
        echo "Failed to get PARTUUID for $1" >&2
        exit 1
    }
    printf '%s\n' "$uuid"
}

bootfs_device_for_rootfs_slot() {
    case "$1" in
        rootfs.0) echo "/dev/mmcblk0p2" ;;
        rootfs.1) echo "/dev/mmcblk0p4" ;;
        *)
            echo "Unknown rootfs slot: $1" >&2
            exit 1
            ;;
    esac
}

rootfs_device_for_bootfs_slot() {
    case "$1" in
        bootfs.0) echo "/dev/mmcblk0p3" ;;
        bootfs.1) echo "/dev/mmcblk0p5" ;;
        *)
            echo "Unknown bootfs slot: $1" >&2
            exit 1
            ;;
    esac
}

update_fstab_partuuids() {
    fstab="$1"
    boot_partuuid="$2"
    root_partuuid="$3"

    awk -v boot="PARTUUID=${boot_partuuid}" -v root="PARTUUID=${root_partuuid}" '
        $2 == "/boot/firmware" { $1 = boot; print; next }
        $2 == "/"              { $1 = root; print; next }
                               { print }
    ' "$fstab" > "$fstab.tmp"

    mv "$fstab.tmp" "$fstab"
}

slot_pre_install() {
    :
}

slot_post_install() {
    case "${RAUC_SLOT_CLASS:-}" in
        rootfs)
            root_partuuid="$(partuuid_of "$RAUC_SLOT_DEVICE")"
            bootfs_dev="$(bootfs_device_for_rootfs_slot "$RAUC_SLOT_NAME")"
            boot_partuuid="$(partuuid_of "$bootfs_dev")"

            update_fstab_partuuids \
                "$RAUC_SLOT_MOUNT_POINT/etc/fstab" \
                "$boot_partuuid" \
                "$root_partuuid"
            ;;

        bootfs)
            rootfs_dev="$(rootfs_device_for_bootfs_slot "$RAUC_SLOT_NAME")"
            root_partuuid="$(partuuid_of "$rootfs_dev")"

            printf 'root=PARTUUID=%s rootfstype=ext4 rauc.slot=%s ro rootwait console=serial0,115200 console=tty1\n' \
                "$root_partuuid" "${RAUC_SLOT_BOOTNAME}" \
                >"$RAUC_SLOT_MOUNT_POINT/cmdline.txt.tmp"
            mv "$RAUC_SLOT_MOUNT_POINT/cmdline.txt.tmp" \
               "$RAUC_SLOT_MOUNT_POINT/cmdline.txt"
            ;;

        *)
            echo "Unhandled slot class: ${RAUC_SLOT_CLASS:-}" >&2
            exit 1
            ;;
    esac
}

case "${1:-}" in
    slot-pre-install)  slot_pre_install ;;
    slot-post-install) slot_post_install ;;
    *) exit 0 ;;
esac