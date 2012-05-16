require 'vagrant-hosts'
require 'resolv'

describe VagrantHosts do
  
  before(:each) do
    VagrantHosts::HostManager.any_instance.stub(:shell)
  end
  
  describe VagrantHosts::HostManager do
    let(:resolver) { Resolv::DNS.new }
    let(:host_name) { "host.name" }
    let(:ip) { "192.168.1.2" }
    
    before(:each) do
      @manager = VagrantHosts::HostManager.new(host_name, ip)
    end
    
    describe "setup" do
      it "should take the host to manage as initializer argument" do
        @manager.hostname.should == host_name
      end
      
      it "should take ip address as constructor argument" do
        @manager.ip.should == ip
      end
      
    end
    
    #describe "adding hostnames" do
    #  
    #  it "should be able to create a hostname" do
    #    @host_mock.should_receive(:add).once
    #    @manager.add_host_entry
    #  end
    #  
    #end
    
    #describe "removing hostnames" do
    #  
    #  it "should be able to delete a hostname" do
    #    @host_mock.should_receive(:delete).once
    #    @manager.remove_host_entry
    #  end
    #  
    #end
    
  end
  
  describe VagrantHosts::HostsConfig do
    
    include Vagrant::TestHelpers
    
    before(:each) do
      @env = vagrant_env
      @config = VagrantHosts::HostsConfig.new
      @errors = Vagrant::Config::ErrorRecorder.new
    end
    
    it "should configure :hostnames" do
      @env.config.global.hosts.should be_kind_of VagrantHosts::HostsConfig
    end
    
    it "should allow no configuration" do
      @config.validate(@env, @errors)
      @errors.errors.should be_empty
    end
    
    it "should allow array of names" do
      @config.names = ['example.net', 'example.com']
      
      @config.validate(@env, @errors)
      @errors.errors.should be_empty
    end
    
    it "should allow empty array of names" do
      @config.names = []
      
      @config.validate(@env, @errors)
      @errors.errors.should be_empty
    end
    
    it "should error on non array for hostnames" do
      @config.names = 23
      
      @config.validate(@env, @errors)
      @errors.errors.should_not be_empty
    end
    
    it "should error on hostnames that are not strings" do
      @config.names = [23]
      
      @config.validate(@env, @errors)
      @errors.errors.should_not be_empty, "#{@errors.inspect}"
    end
    
    it "should always return valid array from hostnames" do
      @config.hostnames.should == []
    end
    
  #  it "should allow indirection to json" # TODO: decide: special config for that?
  end
  
  describe VagrantHosts::HostsManagingMiddleware do
    include Vagrant::TestHelpers
    
    before(:each) do
      @klass = VagrantHosts::HostsManagingMiddleware
      @app, @env = action_env
      @ware = @klass.new(@app, @env)
      @env[:vm].config.hosts.names = ["host.name"]
      @env[:vm].config.vm.network :hostonly, "10.10.10.10"
      @ware.call(@env)
    end
    
    it "should know the hosts to create" do
      @ware.hosts.should == ["host.name"]
    end
    
    it "should know the IP to work with" do
      @ware.ip.should == "10.10.10.10"
    end
    
    it "should have a host manager ready to be called for each host" do
      @ware.managers.should be_a Array
      @ware.managers.all? do |all|
        all.should be_a VagrantHosts::HostManager
        @ware.hosts.should be_include all.hostname
      end
    end
  end
  
end
# middleware to create and remove host entries
#  add support for setting that tells Vagrant where to find the hostname (so you can only specify them once in the vhost definition in json)
# Add middleware everywhere needed so it automatically gets called when the machine boots or dies
# package as nice gem
