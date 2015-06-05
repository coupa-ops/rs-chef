#
# Cookbook Name:: rs-chef
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.

# The Chef client configuration directory
set[:chef][:client][:config_dir] = "/etc/chef"

# The Chef server directories
default[:chef][:server][:config_dir] = '/etc/chef-server'
default[:chef][:server][:prefix] = '/opt/chef-server'

# Recommended attributes
default[:chef][:client][:version] = "11.12.8-2"
default[:chef][:client][:environment] = "_default"

# Required attributes
default[:chef][:client][:server_url] = ""
default[:chef][:client][:validator_pem] = ""
default[:chef][:client][:validation_name] = ""

# Optional attributes
default[:chef][:client][:node_name] = node[:fqdn]
default[:chef][:client][:company] = ""
default[:chef][:client][:roles] = ""
default[:chef][:client][:runlist_override] = ""
# The level of logging that will be stored in the log file
default[:chef][:client][:log_level] = "info"
# The location of the log file
default[:chef][:client][:log_location] = "/var/log/chef-client.log"
# The secret key used to encrypt the data bag items
default[:chef][:client][:data_bag_secret] = ""

