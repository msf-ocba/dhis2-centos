Vagrant.configure(2) do |config|
  config.vm.box = 'bento/centos-7'

  config.vm.provider 'virtualbox' do |v|
    v.memory = 2048
    v.cpus = 2
  end
  config.vm.provider 'vmware_fusion' do |v|
    v.vmx['memsize'] = 2048
    v.vmx['numvcpus'] = 2
  end
  config.vm.provider 'vmware_workstation' do |v|
    v.vmx['memsize'] = 2048
    v.vmx['numvcpus'] = 2
  end
  config.vm.provider 'parallels' do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.provision :shell, :inline  => "rm /etc/environment"
  config.vm.provision :shell, :inline  => "echo http_proxy='http://10.111.112.20:8080/' >> /etc/environment"
  config.vm.provision :shell, :inline  => "echo https_proxy='http://10.111.112.20:8080/' >> /etc/environment"
  config.vm.provision :shell, :inline  => "echo ftp_proxy='http://10.111.112.20:8080/' >> /etc/environment"
  config.vm.provision :shell, :inline  => "echo no_proxy='.mylan.local,.domain1.com,host1,host2' >> /etc/environment"
  config.vm.provision :shell, :inline  => "sed -i 's/proxy.*//' /etc/yum.conf"
  config.vm.provision :shell, :inline  => "echo proxy=http://10.111.112.20:8080 >> /etc/yum.conf"

  config.vm.provision 'ansible_local' do |ansible|
    ansible.become = true
    ansible.compatibility_mode = '2.0'
    ansible.playbook = 'main.yml'
    ansible.verbose = false
    ansible.extra_vars = { dhis2_version: "2.28" }
  end

  config.vm.network 'forwarded_port', guest: 5432, host: 5432
  config.vm.network 'forwarded_port', guest: 8080, host: 8080
  config.vm.network 'forwarded_port', guest: 80, host: 8888
end
