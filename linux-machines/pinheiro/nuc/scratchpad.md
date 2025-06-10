## Testing zfs in raidz1
```bash
# Create a temporary test-pool
for n in {0..3}; do truncate -s 800m /tmp/mediapool-1-$n.raw; done
truncate -s 1200m /tmp/mediapool-1-4.raw
for n in {0..4}; do truncate -s 1800m /tmp/mediapool-2-$n.raw; done
sudo zpool create -f \
    -o ashift=12 \
    -O xattr=sa \
    -O atime=off \
    -O recordsize=1M \
    -O compression=lz4 \
    -O mountpoint=legacy \
    mediapool \
        raidz1 /tmp/mediapool-1-*.raw
# To test adding an additional vdev later...
# sudo zpool add -f mediapool raidz1 /tmp/mediapool-2-*.raw

# Create a test pool in UTM (using virtual USB-disks)
sudo zpool create -f \
    -o ashift=12 \
    -O xattr=sa \
    -O atime=off \
    -O recordsize=1M \
    -O compression=lz4 \
    -O mountpoint=legacy \
    mediapool \
    raidz1 usb-QEMU_QEMU_HARDDISK_1-0000:00:04.0-4.{2..4}-0:0

# Create a test pool on the USB-stick on the pinherio NUC
sudo zpool create -f \
    -o ashift=12 \
    -O xattr=sa \
    -O atime=off \
    -O recordsize=1M \
    -O compression=lz4 \
    -O mountpoint=legacy \
    mediapool \
        usb-USB_USB_2.0_Flash_223FF3F3-0:0

# Create a big file
sudo dd if=/dev/urandom of=/mnt/mediapool/1gb-random.bin bs=1M count=1024 status=progress

# Clear to get back the proper ids
sudo wipefs -a "/dev/disk/by-id/usb-QEMU_QEMU_HARDDISK_1-0000:00:04.0-4.2-0:0"
sudo wipefs -a "/dev/disk/by-id/usb-QEMU_QEMU_HARDDISK_1-0000:00:04.0-4.7-0:0"

```

