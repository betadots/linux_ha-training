# frozen_string_literal: true
require 'yaml'

# Required Vagrant plugins
plugins = [
  'hostmanager',
  'vbguest',
]

# Nodes configuration is defined in config.yaml
config_file = File.join(__dir__, 'config.yaml')
# Initial vms hash
vms = {}

# Sanity checks
unless File.exist?(config_file)
  puts 'File config.yaml not found. Must be in same dir of Vagrantfile'
  abort
end
plugins.each do |plugin|
  unless Vagrant.has_plugin?("vagrant-#{plugin}")
    puts "ERROR! Wir benoetigen das plugin vagrant-#{plugin}: vagrant plugin install vagrant-#{plugin}"
    abort
  end
end

# read config
config = YAML.load_file config_file

# parse config, merge defaults, add required data
config['nodes'].each do |node, conf|
  vms[node] = {}
  vms[node] = config['default'].merge conf
  vms[node]['fqdn'] = format('%<role>s.%<domain>s', role: node, domain: vms[node]['domain'])
  vms[node]['aliases'] = [
    format('%<role>s.%<domain>s %<role>s', role: node, domain: vms[node]['domain'])
  ]
end

# Vagrant configuration
Vagrant.configure('2') do |configs|
  # defaults for all vms
  configs.hostmanager.enabled = true
  configs.hostmanager.manage_host = true
  configs.hostmanager.ignore_private_ip = false
  configs.hostmanager.include_offline = true
  # See https://github.com/mitchellh/vagrant/issues/1673
  configs.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  # config per vm
  vms.each do |node, settings|
    configs.vm.define settings['fqdn'] do |setting|
      setting.vm.box = settings['box']
      if settings['box'].start_with?('centos')
        setting.vbguest.installer_options = { allow_kernel_upgrade: true }
      else
        if Vagrant.has_plugin?("vagrant-vbguest")
          setting.vbguest.auto_update = false
        end
      end
      setting.vm.hostname = settings['fqdn']
      setting.vm.network :private_network, ip: settings['ip1'] # , auto_config: false
      setting.vm.network :private_network, ip: settings['ip2'] # , auto_config: false
      setting.vm.provision 'shell', path: 'scripts/postinstall.sh', args: settings['fqdn'].to_s
      setting.hostmanager.aliases = settings['aliases']
      setting.vm.provider 'virtualbox' do |v|
        file_to_disk = [
          "disks/#{settings['fqdn']}-first_disk.vmdk",
          "disks/#{settings['fqdn']}-second_disk.vmdk"
        ]
        v.customize ['modifyvm', :id, '--name', settings['fqdn']]
        v.customize ['modifyvm', :id, '--cpus', settings['cpu'].to_s]
        v.customize ['modifyvm', :id, '--memory', settings['memory'].to_s]
        if settings['additional_disk_size']
          file_to_disk.each_with_index do |disk, index|
            unless File.exist?(disk)
              v.customize [ "createmedium", "disk", "--filename", disk, "--format", "vmdk", "--size", 1024 * settings['additional_disk_size'] ]
            end
            v.customize [ "storageattach", settings['fqdn'] , "--storagectl", "SATA Controller", "--port", "#{index+1}", "--device", "0", "--type", "hdd", "--medium", disk]
          end
        end
      end
    end
  end
end
