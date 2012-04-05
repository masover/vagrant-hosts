require 'ghost'
require 'vagrant-hosts/plugin'

Vagrant.config_keys.register(:hosts) {VagrantHosts::HostsConfig}

# TODO: find out if this needs to be in more chains
[:start, :up, :reload, :resume].each do |each|
  Vagrant.actions[each].use VagrantHosts::HostsSetupMiddleware
end
[:destroy, :suspend].each do |each|
  Vagrant.actions[each].use VagrantHosts::HostsTeardownMiddleware
end
