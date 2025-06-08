IMAGE_BOX = "bento/debian-12"
IMAGE_VERSION = "202502.21.0"
DIR_SSHKEY_PUB = "C:/Users/Pichau/.ssh/id_ed25519.pub"
DIR_SSHKEY = "C:/Users/Pichau/.ssh/id_ed25519"
DIR_ANSKEY_PUB = "ssh_key/ansible-new_rsa.pub"
DIR_ANSKEY= "ssh_key/ansible-new_rsa"

IP_CP = "192.168.103.10"

ANSIBLE_PUB_KEY = File.read(DIR_ANSKEY_PUB).strip

Vagrant.configure("2") do |config|

    NODE_COUNT = 2 #setando a quantidade de targets
    PROVIDER = "virtualbox"

    config.vm.box = "#{IMAGE_BOX}"
    
    config.vm.define "ansible-master" do |p|
        p.vm.box_version = "#{IMAGE_VERSION}"
        p.vm.network "private_network", ip: "#{IP_CP}"
        p.vm.provider "#{PROVIDER}" do |vb|
            vb.gui = false
            vb.cpus = 2
            vb.memory = "2048"
        end

        p.ssh.insert_key = false
        p.ssh.private_key_path = ["#{DIR_SSHKEY}"]
        p.vm.provision "file", source: "#{DIR_SSHKEY_PUB}", destination: "~/.ssh/authorized_keys"
        p.vm.provision "file", source: "#{DIR_ANSKEY}", destination: "/home/vagrant/.ssh/ansible_key"
        p.vm.provision "file", source: "#{DIR_ANSKEY_PUB}", destination: "/home/vagrant/.ssh/ansible_key.pub"
        
        p.vm.provision "shell", inline: <<-SHELL
            hostnamectl set-hostname ansible-master
            echo "192.168.103.10 ansible-master" >> /etc/hosts
            ######
            chmod 644 ansible-new_rsa.pub
            chmod 600 ansible-new_rsa
            chmod 
        SHELL

        #p.vm.provision "setup", type: "shell", path: "scripts/setup.sh"

    end

    (1..NODE_COUNT).each do |i|
        config.vm.define "ansible-target#{i}" do |target|
            ip_wk = "192.168.103.1#{i+0}"
            
            target.vm.hostname = "ansible-target#{i}"
            target.vm.network "private_network", ip: ip_wk
            target.vm.provider "#{PROVIDER}" do |vbw|
                vbw.gui = false
                vbw.cpus = 2
                vbw.memory = 2048
            end

            target.ssh.insert_key = false
            target.ssh.private_key_path = ["#{DIR_SSHKEY}"]
            target.vm.provision "file", source: "#{DIR_SSHKEY_PUB}", destination: "~/.ssh/authorized_keys"

            
            target.vm.provision "shell", inline: <<-SHELL
                hostnamectl set-hostname ansible-target#{i}
                echo "#{ip_wk} ansible-target#{i}" >> /etc/hosts
                echo "#{ANSIBLE_PUB_KEY}" >> /home/vagrant/.ssh/authorized_keys
            SHELL
        end
    end
end
     