#!/usr/bin/env ruby

require 'vagrant'

module VagrantHosts
  class HostManager
    attr_accessor :hostname, :ip, :ghost
  
    def initialize(hostname, ip, ghost=Host)
      self.hostname = hostname
      self.ip = ip
      self.ghost = ghost
    end
    
    def add_host_entry
      self.ghost.add(hostname, ip)
    end
  
    def remove_host_entry
      self.ghost.delete(hostname)
    end
  
  end
  
  class HostsConfig < Vagrant::Config::Base
    attr_accessor :names
    
    def hostnames()
      self.names || []
    end
    
    def validate(errors)
      return if names.nil?
      return if names.is_a? Array and names.all? { |each| each.is_a? String }
      errors.add(":names needs to be set to an array of strings")
    end
  end

  
  class HostsManagingMiddleware
    def initialize(app, env)
      @app = app
    end
    
    def hosts()
      @env['vm'].config.hosts.hostnames
    end
    
    def ip()
      # is this really the right way to do it?
      # Vagrant doesn't seem to be sure
      # why it needs a list of ip addresses,
      # so just pick the first one
      @env['vm'].config.vm.networks[0][1].first
    end
    
    def managers
      hosts.map { |each| HostManager.new each, ip }
    end
    
    def call(env)
      @env = env
      @app.call(env)
    end
    
  end
  
  class HostsSetupMiddleware < HostsManagingMiddleware
    def call(env)
      super
      if not hosts.empty?
        env[:ui].info "Setting up hostnames"
        managers.each { |each| each.add_host_entry }
      end
      @app.call(env)
    end
  end
  
  class HostsTeardownMiddleware < HostsManagingMiddleware
    def call(env)
      super
      if not hosts.empty?
        env[:ui].info "Tearing down hostnames"
        managers.each { |each| each.remove_host_entry }
      end
      @app.call(env)
    end
  end
end
