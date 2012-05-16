require 'vagrant-hosts/plugin'

Vagrant.config_keys.register(:hosts) {VagrantHosts::HostsConfig}

[:up, :reload, :resume].each do |each|
  Vagrant.actions[each].use VagrantHosts::HostsSetupMiddleware
end

[:destroy, :suspend].each do |each|
  Vagrant.actions[each].use VagrantHosts::HostsTeardownMiddleware
end
