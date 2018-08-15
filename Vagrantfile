Vagrant.configure(2) do |config|
  config.vm.define "jenkins" do |jenkins|
    jenkins.vm.box = "ubuntu/trusty64"
    jenkins.vm.network "private_network", ip: "192.168.0.252"
    jenkins.vm.hostname = "jenkins.example.com"
    jenkins.vm.provider "virtualbox" do |v|
      v.memory = 4096
      v.cpus = 2
    end
   end
   config.vm.define "webserver" do |webserver|
    webserver.vm.box = "ubuntu/trusty64"
    webserver.vm.network "private_network", ip: "192.168.0.3"
    webserver.vm.hostname = "webserver.example.com"
    webserver.vm.provision :shell, path: "webserver-bootstrap.sh"
    webserver.vm.provision "shell",
    	inline: "export JAVA_HOME=`update-alternatives --config java | awk -F: '{print $2}' | tr -ds ' ' '\n'`"
  end
end
