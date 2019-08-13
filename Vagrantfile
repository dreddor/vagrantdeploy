VAGRANT_COMMAND = ARGV[0]

require 'yaml'

current_dir    = File.dirname(File.expand_path(__FILE__))
userconfig = YAML.load_file("#{current_dir}/userconfig.yaml")

Vagrant.configure(2) do |config|
    config.vm.box = "bento/ubuntu-18.04"
    config.vm.provision :shell, :path => "bootstrap.sh"

    config.vm.define :mdw do |mdw|
        mdw.vm.hostname = "mdw.gpdbdev.local"
        mdw.vm.network "forwarded_port", guest: 15432, host: 15432
    end

    config.vm.provider "hyperv" do |h|
        h.cpus = userconfig['cpus']
        h.maxmemory = userconfig['memory']
    end

    config.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--memory", userconfig['memory']]
        vb.customize ["modifyvm", :id, "--cpus", userconfig['cpus']]
    end

    config.ssh.forward_x11 = true
    config.ssh.forward_agent = true

    if VAGRANT_COMMAND == "ssh"
        config.ssh.username = userconfig['user']
        config.ssh.private_key_path = './ssh/id_rsa'
    end
end

