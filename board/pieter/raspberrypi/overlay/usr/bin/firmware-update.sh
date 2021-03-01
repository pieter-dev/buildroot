#!/bin/sh

ROOTFS_IMAGE=/tmp/rootfs.ext2
if [ ! -f $ROOTFS_IMAGE ]; then
	echo "error: rootfs image not found: $ROOTFS_IMAGE!"
	exit 1
fi

CMDLINE=$(cat /proc/cmdline)
for opt in $CMDLINE; do
	case "$opt" in
		root=*)
			ROOT=${opt##*=}
			;;
	esac
done

if [ -z "$ROOT" ]; then
	echo "error: cmdline does not specify a root filesystem: $CMDLINE!"
	exit 1
fi

case "$ROOT" in
	/dev/mmcblk0p2)
		ROOTFS_PARTITION=/dev/mmcblk0p3
		;;
	/dev/mmcblk0p3)
		ROOTFS_PARTITION=/dev/mmcblk0p2
		;;
esac

echo "info: updating $ROOTFS_PARTITION with $ROOTFS_IMAGE ..."
dd if=$ROOTFS_IMAGE of=$ROOTFS_PARTITION

if [ $? -ne 0 ]; then
	echo "error: updating $ROOTFS_PARTITION with $ROOTFS_IMAGE failed!"
	exit 1
fi

echo "info: updated $ROOTFS_PARTITION with $ROOTFS_IMAGE ..."

echo "info: updating boot cmdline, changing root to $ROOTFS_PARTITION ..."

BOOT_PARTITION=/dev/mmcblk0p1
BOOT_MOUNT=/tmp/boot
BOOT_CMDLINE=$BOOT_MOUNT/cmdline.txt

mkdir -p $BOOT_MOUNT
mount $BOOT_PARTITION $BOOT_MOUNT
if [ $? -ne 0 ]; then
	echo "error: mounting $BOOT_PARTITION on $BOOT_MOUNT failed!"
	exit 1
fi

FR=${ROOT##*/}
TO=${ROOTFS_PARTITION##*/}
sed -i "s/$FR/$TO/" $BOOT_CMDLINE
if [ $? -ne 0 ]; then
	echo "error: updating $BOOT_CMDLINE failed!"
	exit 1
fi

umount $BOOT_PARTITION

echo "info: rebooting ..."
reboot

