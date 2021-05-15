
setup-user-admin(){
cat <<SH | chmnt /bin/sh
  apk add shadow sudo

  adduser -D admin
  # sudo NOPASSWORD
  echo 'admin ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
  echo admin:${ADMIN_PASSWORD:-admin} | chpasswd
  mkdir -p /home/admin/.ssh
  wget -O /home/admin/.ssh/authorized_keys https://github.com/Xe.keys

  adduser admin adm
SH
}
