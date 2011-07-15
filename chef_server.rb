require 'chef/config'
require 'net/ssh'
require 'chef'
require 'chef/knife'
require 'chef/knife/bootstrap'
require 'chef/knife/ssh'

class ChefServer < Chef::Knife
  def initialize
    Chef::Config.from_file(".chef/knife.rb")
    @rest = Chef::REST.new("http://109.144.10.241:4000")
    super
  end

  def bootstrap ip_address, node_name, role, identity_file
    Chef::Knife::Bootstrap.load_deps
    #puts "knife bootstrap #{ip_address} -i #{TMP_KEYFILE} -N #{node_name} -d centos5-gems-mtu"
    #`knife bootstrap #{ip_address} -i #{TMP_KEYFILE} -N #{node_name} -d centos5-gems-mtu`
      bootstrap                                       = Chef::Knife::Bootstrap.new
      bootstrap.name_args                             = [ip_address]
      bootstrap.config[:run_list]                     = role
      bootstrap.config[:ssh_user]                     = "root"
      bootstrap.config[:identity_file]                = identity_file
      bootstrap.config[:chef_node_name]               = node_name
      bootstrap.config[:public_ip]                    = ip_address
      bootstrap.config[:prerelease]                   = false
      bootstrap.config[:distro]                       = "centos5-gems-mtu"
      bootstrap.config[:use_sudo]                     = true
      bootstrap.config[:environment]                  = "test_colosseum"
      bootstrap.run
  end

  def add_role_to_runlist node_name, role
    node = Chef::Node.load(node_name)
    node.run_list << role
  end

  def delete_node node_id
    if rest.get_rest("/nodes/#{node_id}")
      rest.delete_rest("/nodes/#{node_id}")
    end
  end
end

