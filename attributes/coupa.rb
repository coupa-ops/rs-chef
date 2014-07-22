default[:coupa][:deployment] = ""
default[:coupa][:role] = "coupa_base"
default[:coupa][:serverdomain] = "coupadev.com"
default[:coupa][:nodename] = node[:fqdn]

# Enable EBS is needed
default[:coupa][:vol][:stripe_count] = "0"
default[:coupa][:vol][:iops] = "0"
default[:coupa][:vol][:size] = "50"

# Change DNSMadeEasy Id
default[:coupa][:dns][:update] = "none"
default[:coupa][:dns][:id] = "000000"
default[:coupa][:dns][:provider] = "DNSMadeEasy"
