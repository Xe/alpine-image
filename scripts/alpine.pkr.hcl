variable "mirror" {
  default = "http://dl-cdn.alpinelinux.org/alpine"
}
variable "version" {
  default = "3.13.5"
}
variable "ver" {
  default = "edge"
}
variable "flavor" {
  default = "virt"
}

variable "size" {
  default = "2G"
}
variable "format" {
  default = "qcow2"
  description = "qcow2, raw"
}

variable "accel" {
  default = "hvf"
  description = "hvf for macOS"
}
variable "boot_wait" {
  default = "10s"
  description = "if no accel, should set at least 30s"
}
variable "dist" {
  default = ""
}

locals {
  ver = regex_replace(var.version, "[.][0-9]+$", "")
  checksums = {
    "alpine-virt-3.13.5-x86_64.iso": "sha256:e6bbcab275b704bc6521781f2342fff084700b458711fdf315a5816d9885943c"
  }
}

source "qemu" "alpine" {
  iso_url = "${var.mirror}/${local.ver}/releases/x86_64/alpine-virt-${var.version}-x86_64.iso"
  iso_checksum = local.checksums["alpine-virt-${var.version}-x86_64.iso"]
  // display = "cocoa"
  headless = true
  accelerator = var.accel
  ssh_username = "root"
  ssh_password = "root"
  ssh_timeout = "2m"

  boot_key_interval = "10ms"
  boot_wait = var.boot_wait
  boot_command = [
    "root<enter>",
    "setup-interfaces -a<enter>",
    "service networking restart<enter>",
    "echo root:root | chpasswd<enter><wait5>",
    "setup-sshd -c openssh<enter>",
    "echo PermitRootLogin yes >> /etc/ssh/sshd_config<enter>",
    "service sshd restart<enter>",
  ]

  disk_size = var.size
  format = var.format

  output_directory = var.dist
}

build {
  source "qemu.alpine" {}

  provisioner "shell" {

    inline = [
<<-EOF
: $${ALPINE_MIRROR:=https://mirrors.aliyun.com/alpine}
: $${ALPINE_FLAVOR:=virt}
echo Building $${ALPINE_VER} using $${ALPINE_MIRROR}
echo $${ALPINE_MIRROR}/$${ALPINE_VER}/main > /etc/apk/repositories
echo $${ALPINE_MIRROR}/$${ALPINE_VER}/community >> /etc/apk/repositories
echo $${ALPINE_MIRROR}/$${ALPINE_VER}/testing >> /etc/apk/repositories
rc-update add networking
ERASE_DISKS=/dev/vda setup-disk -m sys -s 0 -k $${ALPINE_FLAVOR} /dev/vda

mount /dev/vda2 /mnt
mount /dev/vda1 /mnt/boot

chroot /mnt /bin/sh -c 'apk add cloud-init cloud-init-openrc util-linux chrony chrony-openrc bash'
chroot /mnt /bin/sh -c 'setup-cloud-init'
chroot /mnt /bin/sh -c 'rc-update add chronyd default'
sed -i '/PermitRootLogin/d' /mnt/etc/ssh/sshd_config

umount /mnt/boot
umount /mnt
EOF
    ]
    environment_vars = [
      "ALPINE_MIRROR=${var.mirror}",
      "ALPINE_FLAVOR=${var.flavor}",
      "ALPINE_VER=${var.ver}",
    ]
  }
}
