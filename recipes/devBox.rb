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

include_recipe "webapp"


#webapp_members = search("node", "role:#{node['role']['webapp']} AND chef_environment:#{node.chef_environment}") || []
#webapp_members = webapp_members.uniq.sort_by {|x| x['ipaddress'].split(/\./).map {|i| i.to_i}}

# There will not be any HAProxy server when we will create webapp dev box.
# We will install Riak, RabbitMQ and webapp servers on single node.
haproxy_ip = "#{node.ipaddress}"

webapp_members = Array.new
webapp_members << node

template "/opt/app/webapp/conf/hazelcast.xml" do
  source "hazelcast-devBox.xml.erb"
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

