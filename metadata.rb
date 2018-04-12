name             "rs-chef"
maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          "Copyright RightScale, Inc. All rights reserved."
description      "Installs and configures the Chef Client and Server"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "15.0.5"

supports "centos"
supports "redhat"
supports "ubuntu"

depends "collectd", "~> 1.1.0"
depends "machine_tag", "~> 1.0.6"
depends "postgresql", "~> 3.4.1"
depends "database", "~> 1.3.8"

recipe "rs-chef::client",
  "Installs and configures the Chef Client."

recipe "rs-chef::do_client_converge",
  "Allows manual update/re-run of runlist on the Chef Client."

recipe "rs-chef::do_unregister_request",
  "Deletes the node and registered client on the Chef Server."

recipe "rs-chef::client",
  "Propagate coupa attributes"

recipe "rs-chef::server",
  "Installs and configures chef server"

recipe "rs-chef::server_monitoring",
  "Set up RS monitoring"

recipe "rs-chef::server_postgresql",
  "Set up postgresql service"

recipe "rs-chef::run_recipe",
  "Run custom recipe"

recipe "rs-chef::decomm",
  "Run decommission role"

recipe "rs-chef::security-updates",
  "Apply security updates. Install patches packages."

attribute "chef/client/version",
  :display_name => "Chef Client Version",
  :description =>
    "Specify the Chef Client version to match requirements of your Chef" +
    " Server. Example: 11.12.8-2",
  :required => "optional",
  :default => "11.12.8-2",
  :recipes => ["rs-chef::client"]

attribute "chef/server/version",
  :display_name => "Chef Server Version",
  :description =>
    "Specify the Chef Server version to match requirements of your Chef" +
    " Server. Example: 11.1.3-1",
  :required => false,
  :default => "11.1.3-1",
  :recipes => ["rs-chef::server"]

attribute "chef/client/server_url",
  :display_name => "Chef Server URL",
  :description =>
    "Enter the URL to connect to the remote Chef Server. To connect to the" +
    " Opscode Hosted Chef use the following syntax" +
    " https://api.opscode.com/organizations/ORGNAME." +
    " Example: http://example.com:4000/chef",
  :required => "required",
  :recipes => ["rs-chef::client"]

attribute "chef/client/validator_pem",
  :display_name => "Private Key to Register the Chef Client with the Chef" +
    " Server",
  :description =>
    "Private SSH key which will be used to authenticate the Chef Client on" +
    " the remote Chef Server.",
  :required => "required",
  :recipes => ["rs-chef::client", "rs-chef::server"]

attribute "chef/client/ca_file",
  :display_name => "HTTPS CA File",
  :description => "CA File to be used to verify https connection to a chef server.",
  :required => false,
  :recipes => ["rs-chef::client"]

attribute "chef/client/validation_name",
  :display_name => "Chef Client Validation Name",
  :description =>
    "Validation name, along with the private SSH key, is used to determine" +
    " whether the Chef Client may register with the Chef Server. The" +
    " validation_name located on the Server and in the Client configuration" +
    " file must match. Example: ORG-validator",
  :required => "required",
  :recipes => ["rs-chef::client"]

attribute "chef/client/node_name",
  :display_name => "Chef Client Node Name",
  :description =>
    "Name which will be used to authenticate the Chef Client on the remote" +
    " Chef Server. If nothing is specified, the instance FQDN will be used." +
    " Example: chef-client-host1",
  :required => "optional",
  :recipes => ["rs-chef::client"]

attribute "chef/client/environment",
  :display_name => "Chef Client Environment",
  :description =>
    "Specify the environment type for the Chef Client configuration file." +
    " Example: development",
  :required => "optional",
  :default => "_default",
  :recipes => ["rs-chef::client"]

attribute "chef/client/company",
  :display_name => "Chef Company Name",
  :description =>
    "Company name to be set in the Client configuration file. This attribute" +
    " is applicable for Opscode Hosted Chef Server. The company name" +
    " specified in both the Server and the Client configuration file must" +
    " match. Example: MyCompany",
  :required => "optional",
  :recipes => ["rs-chef::client"]

attribute "chef/client/roles",
  :display_name => "Set of Client Roles",
  :description =>
    "Comma-separated list of roles which will be applied to this instance." +
    " The Chef Client will execute the roles in the order specified here." +
    " Example: webserver, monitoring",
  :required => "optional",
  :recipes => ["rs-chef::client", "rs-chef::do_client_converge"]

attribute "chef/client/runlist_override",
  :display_name => "JSON String used to override the first run of chef-client.",
  :description =>
    "A custom JSON string to override the first run of chef-client." +
    " Example: recipe[ntp::default]",
  :required => "optional",
  :recipes => ["rs-chef::client"]

attribute "chef/client/log_level",
  :display_name => "Logging Level",
  :description =>
    "The level of logging that will be stored in the log file. Example: debug",
  :required => "optional",
  :default => "info",
  :recipes => ["rs-chef::client"]

attribute "chef/client/log_location",
  :display_name => "Log File Location",
  :description =>
    "The location of the log file. Example: /var/log/chef-client.log",
  :required => "optional",
  :default => "/var/log/chef-client.log",
  :recipes => ["rs-chef::client"]

attribute "chef/client/strace",
  :display_name => "Do a strace for chef-client run",
  :description => "If true, chef-client will run under strace to trace all system calls.",
  :required => false,
  :default => "false",
  :choice => ["false", "true"],
  :recipes => ["rs-chef::client"]

attribute "chef/client/data_bag_secret",
  :display_name => "Data Bag Secret Key",
  :description =>
    "A secret key used to encrypt data bag items." +
    " Example: cred:CHEF_DATA_BAG_SECRET",
  :required => "optional",
  :default => "",
  :recipes => ["rs-chef::client"]

attribute "coupa/deployment",
  :display_name => "Coupa Deployment",
  :description =>
    "Specify the deployment name",
  :required => "required",
  :recipes => ["rs-chef::client", "rs-chef::server"]

attribute "coupa/serverdomain",
  :display_name => "Coupa serverdomain",
  :description =>
    "Specify the serverdomain coupadev.com/coupahost.com",
  :required => "required",
  :choice => ["coupadev.com", "coupahost.com"],
  :recipes => ["rs-chef::client", "rs-chef::server", "rs-chef::security-updates"]

attribute "coupa/nodename",
  :display_name => "Node name for the server",
  :description =>
    "Specify the nickname",
  :required => "optional",
  :default => "",
  :recipes => ["rs-chef::client", "rs-chef::server"]

# Enable EBS is needed
attribute "coupa/vol/stripe_count",
  :display_name => "How many stripes of EBS",
  :description =>
    "Number of stripes for volume, dafault is 0 meaning do not attach any volume",
  :required => "optional",
  :recipes => ["rs-chef::client"]

attribute "coupa/vol/iops",
  :display_name => "Total IOPS",
  :description =>
    "IOPS for all the volume stripes, default is none",
  :required => "optional",
  :recipes => ["rs-chef::client"]

attribute "coupa/vol/size",
  :display_name => "Total size for all stripes",
  :description =>
    "Total size in GB, sum of all volume stripes, default is 50GB",
  :required => "optional",
  :recipes => ["rs-chef::client"]

attribute "coupa/vol/type",
  :display_name => "Volume Type",
  :description =>
    "Volume type. Could be: (provisioned_ssd) io1 - Provisioned IOPS (SSD); (general_ssd) gp2 - General Purpose (SSD); (magnetic) standard - Magnetic",
  :required => "optional",
  :recipes => ["rs-chef::client"],
  :choice => ["magnetic", "provisioned_ssd", "general_ssd"],
  :default => "magnetic"

attribute "coupa/vol/encrypted",
  :display_name => "Encryption for Volume",
  :description =>
    "Use encryption for a volume or not",
  :required => "optional",
  :recipes => ["rs-chef::client"],
  :choice => ["true", "false"],
  :default => "true"

attribute 'coupa/stack_release',
  :display_name => 'Coupa Stack Release Version',
  :description => 'Coupa Stack Release Version, example es4.4',
  :required => 'optional',
  :recipes => ['rs-chef::client'],
  :default => 'es4.4'

attribute "coupa/s3/access_key",
  :display_name => "AWS ACCESS KEY for S3",
  :description =>
    "The aws access key to be used to work with S3 buckets",
  :required => true,
  :recipes => ["rs-chef::server"]

attribute "coupa/s3/secret_key",
  :display_name => "AWS SECRET KEY for S3",
  :description =>
    "The aws access secret key to be used to work with S3 buckets",
  :required => true,
  :recipes => ["rs-chef::server"]

attribute "chef/server/db_master_user",
  :display_name => "Chef Server DB Master User",
  :description => "The username to be used to connect to chef server database with the root accees",
  :required => true,
  :recipes => ["rs-chef::server"]

attribute "chef/server/db_master_user_password",
  :display_name => "Chef Server DB Master Password",
  :description => "The password to be used to connect to chef server database with the root accees",
  :required => true,
  :recipes => ["rs-chef::server"]

attribute "chef/server/db_endpoint",
  :display_name => "Chef Server DB Endpoint",
  :description => "The endpoint of chef server database. Format: Host:Port.",
  :required => true,
  :recipes => ["rs-chef::server"]

attribute "chef/server/ssl_ca_cert",
  :display_name => "SSL CA Cert",
  :description => "The ssl CA certificate to be used on nginx endpoint.",
  :required => false,
  :recipes => ["rs-chef::server"]

attribute "chef/server/ssl_cert",
  :display_name => "SSL Cert",
  :description => "The ssl certificate to be used on nginx endpoint.",
  :required => false,
  :recipes => ["rs-chef::server"]

attribute "chef/server/ssl_cert_key",
  :display_name => "SSL Cert Key",
  :description => "The ssl certificate key to be used on nginx endpoint.",
  :required => false,
  :recipes => ["rs-chef::server"]

attribute "coupa/rs_sketchy",
  :display_name => "RS Sketchy",
  :description => "The sketchy server in RS infrastructure. " +
  "Since the RS_SKETCHY variable in /var/spool/cloud/user-data.rb is deprecated, " +
  "we should use RS input to set it up. Required for monitoring.",
  :required => true,
  :recipes => ["rs-chef::server", "rs-chef::client"]

attribute "coupa/run_recipe",
  :display_name => "Recipe Name",
  :description => "The name of a custom recipe needs to be run.",
  :required => true,
  :recipes => ["rs-chef::run_recipe"]

attribute "coupa/run_recipe_json",
  :display_name => "Recipe Attributes",
  :description => "The json string needs to be passed to chef-client on run custom recipe.",
  :required => false,
  :recipes => ["rs-chef::run_recipe"]

attribute 'postgresql/password/opscode_chef',
  :display_name => 'Postgres opscode_chef password',
  :description => 'Postgres password for opscode_chef login',
  :required => true,
  :recipes => ['rs-chef::server']

attribute 'postgresql/password/opscode_chef_ro',
  :display_name => 'Postgres opscode_chef_ro password',
  :description => 'Postgres password for opscode_chef_ro login',
  :required => true,
  :recipes => ['rs-chef::server']
