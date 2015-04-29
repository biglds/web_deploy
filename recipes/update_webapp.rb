#
# Cookbook Name:: 
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

execute "tomcat7" do
  command "/etc/init.d/tomcat7 stop"
  action :run
end

directory "/opt/app/data/mylogins" do
  owner "tomcat7"
  group "tomcat7"
  action :create
  not_if "test -d /opt/app/data/mylogins"
end

directory "/opt/app/data/mylogins/outbox" do
  owner "tomcat7"
  group "tomcat7"
  action :create
  not_if "test -d /opt/app/data/mylogins/outbox"
end

directory "/opt/app/data/mylogins/outbox/ar" do
  owner "tomcat7"
  group "tomcat7"
  action :create
  not_if "test -d /opt/app/data/mylogins/outbox/ar"
end

directory "/opt/app/data/mylogins/outbox/ar/email" do
  owner "tomcat7"
  group "tomcat7"
  action :create
  not_if "test -d /opt/app/data/mylogins/outbox/ar/email"
end

directory "/opt/app/data/mylogins/outbox/ar/.camel" do
  owner "tomcat7"
  group "tomcat7"
  action :create
  not_if "test -d /opt/app/mylogins/outbox/ar/.camel"
end


# Changes for -3.4 Begin
# Find HAProxy server IP and add it to JAVA_OPTS in /etc/default/tomcat7 file for Riak and RabbitMQ (AMQP)
haproxy_ip = ""
haproxy_nodes = search("node", "role:haproxy AND chef_environment:#{node.chef_environment}") || []

if haproxy_nodes.length > 0
  haproxy_ip = "#{haproxy_nodes.first['ipaddress']}"
end

puts "Hapoxy Public IP: #{haproxy_ip}"



# There will not be any HAProxy server when we will create  dev box.
# We will install Riak, RabbitMQ and  servers on single node.
if (haproxy_ip == "")
  haproxy_ip = "#{node.ipaddress}"
end
template "/etc/default/tomcat7" do
  source "tomcat7.erb"
  mode 0644
  variables({
        :haproxy_ip => haproxy_ip
  })
end

template "/opt/app//tomcat/conf/cadi.properties" do
  source "cadi.properties.erb"
  owner "#{node[:][:tomcat][:user]}"
  group "#{node[:][:tomcat][:group]}"
  mode 0644
end

cookbook_file "/tmp/tempchart.tar.gz" do
  source "/tempchart.tar.gz"
end

execute "extract  tempchart dir" do
  user "root"
  group "root"
  command "tar -zxvf /tmp/tempchart.tar.gz -C /opt/app// && chown -R #{node[:][:tomcat][:user]}:#{node[:][:tomcat][:group]} /opt/app/"
  cwd "/opt/app/"
end
# Changes for -3.4 End


execute "remove_current__application" do
  user "root"
  group "root"
  command "rm -rf #{node['']['home']}/tomcat/webapps/*"
end


cookbook_file "#{node['']['home']}/tomcat/webapps/.war" do
  owner "#{node[:][:tomcat][:user]}"
  group "#{node[:][:tomcat][:group]}"
  source "#{node[:][:war][:snapshot_file_path]}"
end

#Changes for -3.5

cookbook_file "#{node['']['home']}/tomcat/lib/javaee-api-6.0-5.jar" do
  owner "#{node[:][:tomcat][:user]}"
  group "#{node[:][:tomcat][:group]}"
  source "/javaee-api-6.0-5.jar"
end


# Changes for Centralized Logging
centralized_logging_node = ""
centralized_logging_port = "514"

if node['centralized_logging']['enable']
	if node['centralized_logging']['node']
		centralized_logging_node = "#{node['centralized_logging']['node']}"
		centralized_logging_port = "#{node['centralized_logging']['port']}"
	else
		centralized_logging_node = "#{haproxy_ip}"
	end
puts "centralized_logging_node: #{centralized_logging_node}"
puts "centralized_logging_node: #{centralized_logging_port}"
end
puts "centralized_logging enable: #{node['centralized_logging']['enable']}"
template "#{node['']['home']}/conf/logback.xml" do
  	source "logback.xml.erb"
  	mode 0644
  	variables({
        :centralized_logging_node => centralized_logging_node,
 		:centralized_logging_port => centralized_logging_port
  	})
end




execute "tomcat7" do
  command "/etc/init.d/tomcat7 start"
  action :run
end


execute "update__index_file" do
  user "root"
  group "root"
  command "echo '<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"> <html> <head> <title> Redirect</title> <meta http-equiv=\"REFRESH\" content=\"0;url=//\"></head> <body> </body> </html>' > #{node[:][:home]}/tomcat/webapps/ROOT/index.html"

end

