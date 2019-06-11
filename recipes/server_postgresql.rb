#include_recipe "postgresql::client"
include_recipe "postgresql::ruby"

###
# Create the opscode_chef database, migrate it, and create the users we need, and grant them
# privileges.
###
db_name = "opscode_chef"
postgresql_connection_info = {
  :host => node[:chef][:server][:db_endpoint].split(":").first,
  :port => node[:chef][:server][:db_endpoint].split(":").last,
  :username => node[:chef][:server][:db_master_user],
  :password => node[:chef][:server][:db_master_user_password],
}

file "/root/.pgpass" do
  mode 0600
  content "#{postgresql_connection_info[:host]}:#{postgresql_connection_info[:port]}:*:#{postgresql_connection_info[:username]}:#{postgresql_connection_info[:password]}\n"
  action :create
end

postgresql_database db_name do
  connection postgresql_connection_info
  encoding 'UTF-8'
  action :create
  notifies :run, 'execute[install_schema]', :immediately
end

execute "install_schema" do
  command "/opt/chef-server/embedded/bin/sqitch --db-user #{postgresql_connection_info[:username]} --db-host #{postgresql_connection_info[:host]} --db-port #{postgresql_connection_info[:port]} deploy --verify" # same as preflight
  cwd "/opt/chef-server/embedded/service/chef-server-schema"
  environment({'HOME' => '/root'})
  action :nothing
end

# Create Database Users
node['postgresql']['password'].each do |pg_u, pg_p|
  next if pg_u == "postgres"

  postgresql_database_user pg_u do
    password pg_p
    connection postgresql_connection_info
    action :create
  end

  grant_commands = if pg_u.end_with?("_ro")
    [
      "GRANT CONNECT ON DATABASE #{db_name} TO #{pg_u};",
      "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO #{pg_u};",
      "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO #{pg_u};",
      "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO #{pg_u};",
      "GRANT SELECT ON ALL TABLES IN SCHEMA public TO #{pg_u}",
    ]
  else
    [
      "GRANT CONNECT, TEMPORARY ON DATABASE #{db_name} TO #{pg_u};",
      "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, UPDATE ON SEQUENCES TO #{pg_u};",
      "GRANT SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO #{pg_u};",
      "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT INSERT, SELECT, UPDATE, DELETE ON TABLES TO #{pg_u};",
      "GRANT INSERT, SELECT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO #{pg_u}",
    ]
  end + [
    "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO #{pg_u};",
    "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO #{pg_u};",
  ]

  grant_commands.each do |grant_command|

    postgresql_database grant_command do
      connection postgresql_connection_info
      sql grant_command
      database_name db_name
      action :query
    end

  end

end
