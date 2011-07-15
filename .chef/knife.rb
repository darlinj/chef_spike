log_level                :info
log_location             STDOUT
node_name                'joe'
client_key               '/home/joe/code/multi-server-spike/.chef/joe.pem'
#validation_client_name   'chef-validator'
validation_key           '/home/joe/code/multi-server-spike/.chef/validation.pem'
databag_encryption_key   '/home/joe/code/multi-server-spike/.chef/databag_encryption.key'
chef_server_url          'http://109.144.10.241:4000'
cache_type               'BasicFile'
cache_options( :path => '/home/joe/code/multi-server-spike/.chef/checksums' )

