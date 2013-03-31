#
# Cookbook Name:: freepbx
# Recipe:: default
#
# Copyright 2013, Zefiro Networks LLC
#
# All rights reserved - Do Not Redistribute
#
#

#cd /usr/src
#wget http://mirror.freepbx.org/freepbx-2.9.0.tar.gz
#tar zxvf freepbx-2.9.0.tar.gz
#cd /freepbx-2.9.0
#./start_asterisk start   #esto es como el init.d de amportal
#./install_amp
#
# ALL OF THESE SHOULD BE CHEF ATTRIBUTES
version = "freepbx-2.9.0"
package_name = "#{version}.tar.gz"
uri = "http://mirror.freepbx.org"
cdr_database = "asteriskcdrdb"
freepbx_database = "asterisk"
freepbx_user = "asteriskuser"
freepbx_password = "amp109"


execute "download" do
  cwd "/tmp"
  command "wget #{uri}/#{package_name}"
  creates "/tmp/#{package_name}"
  action :run
end

execute "uncompress" do
  cwd "/tmp"
  command "tar xzf #{package_name}"
  creates "/tmp/#{version}"
  action :run
end

execute "create freepbx user" do
  command "mysql -p#{node['mysql']['server_root_password']} -D mysql -r -B -N -e \"CREATE USER '#{freepbx_user}'@'localhost' IDENTIFIED BY '#{freepbx_password}'\""
end

execute "create cdr database" do
  command "mysqladmin create #{cdr_database} -p#{node['mysql']['server_root_password']}"
end

execute "import cdr database schema" do
  cwd "/tmp/#{version}"
  command "mysql -p#{node['mysql']['server_root_password']} #{cdr_database} < SQL/cdr_mysql_table.sql"
end

execute "grant permissions on cdr database to freepbx user" do
  command "mysql -p#{node['mysql']['server_root_password']} #{cdr_database} < SQL/cdr_mysql_table.sql"
  command "mysql -p#{node['mysql']['server_root_password']} -D mysql -r -B -N -e \"GRANT ALL ON #{cdr_database}.* TO '#{freepbx_user}'@'localhost' IDENTIFIED BY '#{freepbx_password}'\""
# mysql> GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO asteriskuser@localhost IDENTIFIED BY 'amp109';
end

execute "create freepbx database" do
  command "mysqladmin create #{freepbx_database} -p#{node['mysql']['server_root_password']}"
end

execute "import freepbx database schema" do
  cwd "/tmp/#{version}"
  command "mysql -p#{node['mysql']['server_root_password']} #{freepbx_database} < SQL/newinstall.sql"
end

execute "grant permissions on freepbx database to freepbx user" do
  command "mysql -p#{node['mysql']['server_root_password']} -D mysql -r -B -N -e \"GRANT ALL ON #{freepbx_database}.* TO '#{freepbx_user}'@'localhost' IDENTIFIED BY '#{freepbx_password}'\""
# mysql> GRANT ALL PRIVILEGES ON asterisk.* TO asteriskuser@localhost IDENTIFIED BY 'amp109';
end

