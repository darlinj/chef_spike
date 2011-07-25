require 'chef/config'
require 'net/ssh'
require 'chef'
require 'chef/knife'
require 'chef/knife/bootstrap'
require 'chef/knife/ssh'

class ChefServer < Chef::Knife
  def initialize
    Chef::Config.from_file(".chef/knife.rb")
    @rest = Chef::REST.new(Chef::Config[:chef_server_url])
    super
  end

  def bootstrap(ip_address, node_name, role, identity_file, environment=nil)
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
      bootstrap.config[:environment]                  = environment
      bootstrap.run
  end

  def add_role_to_runlist node_name, role
    node = Chef::Node.load(node_name)
    node.run_list << role
  end

  def delete_node node_id
    if rest.get_rest("/nodes").keys.include?(node_id) 
      rest.delete_rest("/nodes/#{node_id}")
    end
  end

  def create_environment environment_name
    unless rest.get_rest("/environments").keys.include?(environment_name.chomp) 
      body = { "name" => environment_name.chomp,
        "json_class" => "Chef::Environment",
        "chef_type" => "environment",
        "attributes" => {},
        "description"=> "",
        "cookbook_versions" => {}
      }
      rest.post_rest("environments",body)
    else
      raise "Environment already exists.  Please choose a diferent name"
    end
  end
end

