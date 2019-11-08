#!/bin/bash
set -xe

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -yq -o Dpkg::Options::="--force-confnew" dist-upgrade
sudo apt-get install python-pip git libffi-dev libssl-dev -y

pip install ansible

[ -d /vagrant/ssh ] || mkdir /vagrant/ssh
[ -f /vagrant/ssh/id_rsa ] || ssh-keygen -t rsa -b 4096 -a 100 -f /vagrant/ssh/id_rsa -N ''

cat <<EOF > /tmp/user_vagrant.yaml
---
- hosts: localhost
  vars_files:
    - /vagrant/userconfig.yaml
  become: yes
  tasks:
  - name: Make sure we have a 'wheel' group
    group:
      name: wheel
      state: present

  - name: Make sure we have a 'admin' group
    group:
      name: admin
      state: present

  - name: Allow 'wheel' group to have passwordless sudo
    lineinfile:
      dest: /etc/sudoers
      state: present
      regexp: '^%wheel'
      line: '%wheel ALL=(ALL) NOPASSWD: ALL'
      validate: 'visudo -cf %s'

  - name: Add user {{user}}
    user:
      name: "{{user}}"
      shell: /bin/bash
      generate_ssh_key: no
      password: $6$HXvgnNcq9W/jEMsj$JvJy7zb5eOIBFkDkQS1S3UmPTwoWjzbBynSTlBBJ3ADq3Ltb.qJUKjLpBIYB2ftrGhAfWnuZyAN8uxxPHgxBK0
      groups: wheel,admin

  - name: Set up authorized keys for {{user}}
    authorized_key:
      user: "{{user}}"
      state: present
      key: "{{item}}"
    with_file:
      - /vagrant/ssh/id_rsa.pub

  - name: Install id_rsa for {{user}}
    copy:
      src: /vagrant/ssh/id_rsa
      dest: /home/{{user}}/.ssh/id_rsa
      owner: "{{user}}"
      group: "{{user}}"
      mode: 0600

  - name: Create the ansible directory
    file:
      path: /etc/ansible/
      state: directory
      owner: root
      group: root
      mode: 0755

  - name: Install the ansible hosts file
    copy:
      src: /tmp/hosts
      dest: /etc/ansible/hosts
      owner: root
      group: wheel
      mode: 0640

  - name: Create the deployments directory
    file:
      path: /home/{{user}}/deployments
      state: directory
      owner: "{{user}}"
      group: "{{user}}"
      mode: 0755

  - name: Cloning envsetup into {{user}}/deployments
    git:
      repo: '{{envsetup_repo}}'
      dest: "/home/{{user}}/deployments/envsetup"
      remote: origin
      accept_hostkey: yes
    become: yes
    become_user: "{{user}}"

  - name: Cloning resrictedenv into {{user}}/deployments
    git:
      repo: '{{restricted_repo}}'
      dest: "/home/{{user}}/deployments/restrictedenv"
      remote: origin
      accept_hostkey: yes
    become: yes
    when: use_restricted == True
    become_user: "{{user}}"

  - name: Create init script
    copy:
      dest: "/tmp/runinit.sh"
      content: |
        #!/bin/bash
        set -ex
        INIT_COMMAND_USER={{user}}
        USERESTRICTED={{use_restricted}}

        {{init_command}}
      mode: 750
      owner: root
      group: wheel

EOF

cat <<EOF > /tmp/hosts
[all:vars]
userconfig=/vagrant/userconfig.yaml

[vagrant_workstation]
localhost

[vagrant_workstation:vars]
ansible_connection=local
ansible_python_interpreter="{{ansible_playbook_python}}"
EOF

ansible-playbook /tmp/user_vagrant.yaml
/tmp/runinit.sh
