#cloud-config
autoinstall:
  early-commands:
    - sudo systemctl stop ssh
  identity:
    hostname: "${ hostname }"
    username: "${ username }"
    password: "${ password }"
  late-commands:
    - sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /target/etc/ssh/sshd_config
    - echo "${ username } ALL=(ALL) NOPASSWD:ALL" > /target/etc/sudoers.d/${ username }
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${ username }
    - sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/c\GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1"' /target/etc/default/grub
    - curtin in-target --target /target update-grub2
    - sed -i '/DNSStubListener/c\DNSStubListener=no' /target/etc/systemd/resolved.conf
    - curtin in-target --target /target systemctl restart systemd-resolved.service
    - curtin in-target --target /target systemctl disable systemd-resolved.service
    - curtin in-target --target /target systemctl stop systemd-resolved.service
    - mv /target/etc/resolv.conf /target/etc/resolv.conf.old
    - touch /target/etc/resolv.conf
    - echo "nameserver ${ nameserver }\noptions edns0" > /target/etc/resolv.conf
  locale: en_US
  keyboard:
    layout: us
  network:
    network:
      version: 2
      ethernets:
        mainif:
          match:
            name: e*
          critical: true
          dhcp4: true
          dhcp-identifier: mac
  packages:
    - cloud-guest-utils
    - curl
    - docker.io
    - git
    - gnupg
    - jq
    - net-tools
    - nfs-common
    - open-vm-tools
    - openjdk-8-jdk # for jenkins
    - perl
    - qemu
    - qemu-kvm
    - software-properties-common
    - unzip
    - vim
    - wget
    - zip
  ssh:
    allow-pw: yes
%{ if length( ssh_keys ) > 0 ~}
    authorized-keys:
%{ for ssh_key in ssh_keys ~}
      - ${ ssh_key }
%{ endfor ~}
%{ endif ~}
    install-server: yes
  storage:
    layout:
      name: direct
  user-data:
    package_upgrade: true
    disable_root: true
  version: 1