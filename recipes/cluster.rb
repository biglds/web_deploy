#
# Cookbook Name:: webapp
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#
# Search for all webapp nodes
#
webapp_members = search("node", "role:#{node['role']['webapp']} AND chef_environment:#{node.chef_environment}") || []
#webapp_members << node if node.run_list.roles.include?(node['role']['webapp'])
webapp_members = webapp_members.uniq.sort_by {|x| x['ipaddress'].split(/\./).map {|i| i.to_i}}
puts "webapp Nodes:" 
webapp_members.each {|n| puts n['ipaddress']}

# Find Public IP of HAProxy server and add it to JAVA_OPTS in /etc/default/tomcat7 file for Riak and RabbitMQ (AMQP)
haproxy_ip = ""
haproxy_nodes = search("node", "role:haproxy AND chef_environment:#{node.chef_environment}") || []

if haproxy_nodes.length > 0
  haproxy_ip = "#{haproxy_nodes.first['ipaddress']}"
end

puts "Hapoxy IP: #{haproxy_ip}"


template "/opt/app/webapp/conf/hazelcast.xml" do
  source "hazelcast.xml.erb"
  owner "#{node[:webapp][:tomcat][:user]}"
  group "#{node[:webapp][:tomcat][:group]}"
  mode 0644
  variables({ 'webapp_members' => webapp_members.uniq, 'haproxy_ip' => haproxy_ip })
  notifies :restart, "service[tomcat]"
end

template "/etc/default/tomcat7" do
  source "tomcat7.erb"
  mode 0644
  variables({
        :haproxy_ip => haproxy_ip
  })
  notifies :restart, "service[tomcat]"
end


service "tomcat" do
  service_name "tomcat7"
  supports :restart => true, :reload => true, :status => true
  action [:enable, :restart]
end

