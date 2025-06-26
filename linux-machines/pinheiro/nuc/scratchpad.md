## Swap a disk
autoreplace is on
See: https://chatgpt.com/share/685c7e48-8b60-800d-b9cd-8459808af46a
And see: https://chatgpt.com/c/685d422a-7df4-800d-a780-25479c57e9e4

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

# Create the mediapool using the terramasters disks
sudo zpool create -f \
    -o ashift=12 \
    -O xattr=sa \
    -O atime=off \
    -O recordsize=1M \
    -O compression=lz4 \
    -O mountpoint=legacy \
    mediapool \
    raidz1 usb-ST18000N_T001-3NF101_2024051400025-0:{0..4}

# Create a big file
sudo dd if=/dev/urandom of=/mnt/mediapool/1gb-random.bin bs=1M count=1024 status=progress

# Clear to get back the proper ids
sudo wipefs -a "/dev/disk/by-id/usb-QEMU_QEMU_HARDDISK_1-0000:00:04.0-4.2-0:0"
sudo wipefs -a "/dev/disk/by-id/usb-QEMU_QEMU_HARDDISK_1-0000:00:04.0-4.7-0:0"

```

