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
    - curl
    - open-vm-tools
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