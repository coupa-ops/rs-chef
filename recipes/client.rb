#
# Cookbook Name:: rs-chef
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.

# Copy Chef Client installation script from cookbook files.
# Sourced from https://www.opscode.com/chef/install.sh

class Chef::Recipe
  include Rschef::Helper
end

# Usually, a bundler deletes any pem files, so we need to be sure that we have CA pems.
ruby_block "Check ca-certificates" do
  block do
    list_files = begin
      r = IO.popen("rpm -ql ca-certificates")
      r.readlines.map {|x| x.chomp }
    ensure
      r.close if (r && !r.closed?)
    end

    list_files.reject! {|x| ::File.exists?(x) }

    # If we found a files that must be on FS but they don't, we reinstall ca-certificates
    unless list_files.empty?
      Chef::Log.info "Found missing files: #{list_files.join(", ")}"
      Chef::Log.info "Reinstalling ca-certificates..."
      system("yum reinstall -y ca-certificates")
    end
  end
end


node.override[:coupa][:role] = node[:chef][:client][:roles].split(",").map{|x| x.strip}.join(",")

template "/etc/chef_coupa_attr.json" do
  source "chef_coupa_attr.json.erb"
  owner "root"
  group "root"
  mode "0400"
end

# Ohai not getting ec2 metadata in VPC, trick is to set the hint for ec2 -
# Already added ohai hists to coupa-baker
directory "/etc/chef/ohai/hints" do
  recursive true
  action :create
end

file "/etc/chef/ohai/hints/ec2.json" do
  action(begin
    require 'json'
    s = JSON.parse(::File.read('/var/spool/cloud/meta-data.json'))['services'] || {}
    s['domain'] == 'amazonaws.com' ? :create : :delete
  end)
end

cookbook_file "/tmp/install.sh" do
  source "install.sh"
  mode "0755"
  cookbook "rs-chef"
end

# Installs the Chef Client using user selected version.
execute "install chef client" do
  command "/tmp/install.sh -v #{node[:chef][:client][:version]}"
  only_if {
    begin
      current_version = begin
        r = IO.popen("chef-client --version")
        r.read.chomp
      rescue
        "Chef: 0.0.0"
      ensure
        r.close unless r.closed?
      end.match(/^Chef: (.*)$/)[1]

      needed_version = node[:chef][:client][:version].match(/^([0-9.]+)/)[1]

      Gem::Version.new(current_version) < Gem::Version.new(needed_version)
    end
  }
end

file "/etc/chef/https_ca_file.crt" do
  content node[:chef][:client][:ca_file]
  mode 0600
  not_if { node[:chef][:client][:ca_file].nil? }
end

# right_api_client 1.5 is not compatible with mime-types 2.0 which is required by ohai 8.1.1
ruby_block "Install our own build of right_api_client gem" do
  block do
    require 'open-uri'

    File.open("/tmp/right_api_client-1.5.26.gem", "w") do |f|
      f << open("https://s3.amazonaws.com/packages.#{node[:coupa][:serverdomain]}/right_api_client-1.5.26.gem", ssl_ca_cert: '/etc/ssl/certs/ca-bundle.crt').read
    end

    IO.popen("/opt/chef/embedded/bin/gem install /tmp/right_api_client-1.5.26.gem") {|x| x.read}
    raise "Cannot install local right_api_client gem" unless $?.success?
  end
  only_if {
    current_version = IO.popen("/opt/chef/bin/chef-client --version") {|x| x.read}.match(/^Chef: (.*)$/)[1]
    right_api_client_installed = IO.popen("/opt/chef/embedded/bin/gem list right_api_client") {|x| x.read}.match(/^right_api_client/) && true

    Gem::Version.new(current_version) >= Gem::Version.new("12") && \
    !right_api_client_installed
  }
end
# -----

log "  Chef Client version #{node[:chef][:client][:version]} installation is" +
  " completed."

# Creates the Chef Client configuration directory.
directory node[:chef][:client][:config_dir]

# Calculates node name
chef_node_name = launchnodename(
  node[:chef][:client][:node_name].chars.select { |x| x.match(/[a-z0-9A-Z_-]/) }.join
) + '-' + launchtime
Chef::Log.info "Chef node name: #{chef_node_name}"

# Creates the Chef Client configuration file.
template "#{node[:chef][:client][:config_dir]}/client.rb" do
  source "client.rb.erb"
  mode "0644"
  backup false
  cookbook "rs-chef"
  variables(
    :server_url => node[:chef][:client][:server_url],
    :validation_name => node[:chef][:client][:validation_name],
    :node_name => chef_node_name,
    :ca_file => node[:chef][:client][:ca_file],
    :log_level => node[:chef][:client][:log_level],
    :log_location => node[:chef][:client][:log_location]
  )
end

# Creates the private key to register the Chef Client with the Chef Server.
template "#{node[:chef][:client][:config_dir]}/validation.pem" do
  source "validation_key.erb"
  mode "0600"
  backup false
  cookbook "rs-chef"
  variables(
    :validation_key => node[:chef][:client][:validator_pem]
  )
end

# Creates secret key file used to decrypt data bags if they are encrypted.
file "#{node[:chef][:client][:config_dir]}/encrypted_data_bag_secret" do
  mode 0600
  content node[:chef][:client][:data_bag_secret]
  not_if { node[:chef][:client][:data_bag_secret].to_s.empty? }
end

# Creates runlist.json file.
template "#{node[:chef][:client][:config_dir]}/runlist.json" do
  source "runlist.json.erb"
  cookbook "rs-chef"
  mode "0440"
  backup false
  variables(
    :node_name => chef_node_name,
    :environment => node[:chef][:client][:environment],
    :company => node[:chef][:client][:company],
    :roles => node[:chef][:client][:roles]
  )
end

# Sets current roles for future validation. See recipe chef::do_client_converge.
node.set[:chef][:client][:current_roles] = node[:chef][:client][:roles]

log "  Chef Client configuration is completed."

# Sets command extensions and attributes.
extension = "--json-attributes #{node[:chef][:client][:config_dir]}/runlist.json"
extension << " --environment #{node[:chef][:client][:environment]}" \
  unless node[:chef][:client][:environment].empty?
extension << " --override-runlist #{node[:chef][:client][:runlist_override]}" \
  unless node[:chef][:client][:runlist_override].empty?

strace_chef = (node[:chef][:client][:strace] == "true") ? "strace -f -o #{node[:chef][:client][:log_location]}.strace -T -ttt" : ""

# Runs the Chef Client using command extensions.
execute "run chef-client" do
  command "#{strace_chef} chef-client #{extension}"
  timeout 86_400
end

log "  Chef Client role(s) are: #{node[:chef][:client][:current_roles]}"

log "  Chef Client logging location: #{node[:chef][:client][:log_location]}"
log "  Chef Client logging level: #{node[:chef][:client][:log_level]}"
