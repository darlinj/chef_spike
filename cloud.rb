require "fog_env"
require "fog"

class Cloud
  def initialize
    @compute = Fog::Compute.new( :provider              => FogEnv::PROVIDER,
                                :region                 => FogEnv::REGION,
                                :bt_access_key_id       => FogEnv::BT_ACCESS_KEY_ID,
                                :bt_secret_access_key   => FogEnv::BT_SECRET_ACCESS_KEY)

  end

  def create_keypair keypair_name
    @keypair_name = keypair_name
    if @compute.key_pairs.get(@keypair_name)
      @compute.key_pairs.get(@keypair_name).destroy
    end
    keypair = @compute.key_pairs.create(:name => @keypair_name)
    keyfile = File.open("/tmp/#{@keypair_name}","w")
    keyfile.write(keypair.private_key)
    keyfile.chmod(0600)
    keyfile.close
  end

  def create_security_group group_name
    @group_name=group_name
    security_group = @compute.security_groups.get(group_name)
    unless security_group
      security_group = @compute.security_groups.new(:name => group_name, :description => 'used for origin server testing')
      security_group.save
    end
    security_group.authorize_port_range(22..22)
    security_group.authorize_port_range(80..80)
  end

  def create_servers( number_of_servers, image_id=FogEnv::IMAGE_ID )
    servers = []
    threads = []
    number_of_servers.times do
      server = @compute.servers.create(:image_id => image_id, :groups => [@group_name], :key_name => @keypair_name, :flavor_id=>"c1.xlarge")
      servers << server
      threads << Thread.new(server) do |s|
        puts "\nstarting server: #{s.id}"
        s.wait_for { print "*"; STDOUT.flush; ready? }
        puts "\nserver started: #{s.id}"
        s.reload
        remove_ssh_known_hosts s
        print(".") until tcp_test_ssh(s.dns_name) { puts "\nSSH started on #{s.id}" }
      end
    end
    threads.each { |thread|  thread.join }
    puts "all instances started"
    servers
  end

  def destroy_cluster group_name
    servers = @compute.servers.reject{|d| d.groups != [group_name] }
    servers = servers.reject{|d| d.state != "running" }
    servers.each{|s| s.destroy}
    servers
  end

  private
  def remove_ssh_known_hosts server
    `ssh-keygen -R #{server.dns_name} > /dev/null 2>&1`
  end

  def tcp_test_ssh(hostname)
    retries = 5
    begin
      tcp_socket = TCPSocket.new(hostname, 22)
    rescue
      print '.'
      STDOUT.flush
      sleep(10)
      retry if (retries -= 1) > 0
    end
    return false unless tcp_socket
    puts "\nchecking socket for #{hostname}"
    readable = IO.select([tcp_socket], nil, nil, 5)
    if readable
      yield
      true
    else
      false
    end
  rescue Errno::ETIMEDOUT
    false
  rescue Errno::ECONNREFUSED
    false
  ensure
    tcp_socket && tcp_socket.close
  end


end
