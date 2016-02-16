#!/bin/sh

if ! [ -d ../boot ]; then
  printf "Can't find boot dir. Run from debian subdir\n"
  exit 1
fi

printf "#!/bin/sh\n" > raspberrypi-bootloader.postinst
for FN in ../boot/* ../boot/*/*; do
  if ! [ -d "$FN" ]; then
    FN=${FN#../boot/}
    printf "rm -f /boot/$FN\n" >> raspberrypi-bootloader.postinst
    printf "dpkg-divert --package rpikernelhack --remove --rename /boot/$FN\n" >> raspberrypi-bootloader.postinst
    printf "sync\n" >> raspberrypi-bootloader.postinst
  fi
done
printf "#DEBHELPER#\n" >> raspberrypi-bootloader.postinst

printf "#!/bin/sh\n" > raspberrypi-bootloader.preinst
cat <<EOF >> raspberrypi-bootloader.preinst
if [ -f "/boot/recovery.elf" ]; then
  echo "/boot appears to be NOOBS recovery partition. Applying fix."
  rootnum=\`cat /proc/cmdline | sed -n 's|.*root=/dev/mmcblk0p\([0-9]*\).*|\1|p'\`
  if [ ! "\$rootnum" ];then
    echo "Could not determine root partition"
    exit 1
  fi
  
  if ! grep -qE "/dev/mmcblk0p1\s+/boot" /etc/fstab; then
    echo "Unexpected fstab entry"
    exit 1
  fi

  boot="/dev/mmcblk0p\$((rootnum-1))"
  root="/dev/mmcblk0p\${rootnum}"
  sed /etc/fstab -i -e "s|^.* / |\${root}  / |"
  sed /etc/fstab -i -e "s|^.* /boot |\${boot}  /boot |"
  umount /boot
  if [ \$? -ne 0 ]; then
    echo "Failed to umount /boot. Remount manually and run sudo apt-get install -f."
    exit 1
  else
    mount /boot
  fi
fi
EOF
printf "mkdir -p /usr/share/rpikernelhack/overlays\n" >> raspberrypi-bootloader.preinst
printf "mkdir -p /boot/overlays\n" >> raspberrypi-bootloader.preinst
for FN in ../boot/* ../boot/*/*; do
  if ! [ -d "$FN" ]; then
    FN=${FN#../boot/}
    printf "dpkg-divert --package rpikernelhack --divert /usr/share/rpikernelhack/$FN /boot/$FN\n" >> raspberrypi-bootloader.preinst
  fi
done
printf "#DEBHELPER#\n" >> raspberrypi-bootloader.preinst
