#
# Cookbook Name:: webapp
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
tc7ver = node["webapp"]["tomcat"]["version"]
tc7tarball = "apache-tomcat-#{tc7ver}.tar.gz"
tc7url = "http://archive.apache.org/dist/tomcat/tomcat-7/v#{tc7ver}/bin/#{tc7tarball}"
tc7target = node["webapp"]["tomcat"]["target"]
tc7user = node["webapp"]["tomcat"]["user"]
tc7group = node["webapp"]["tomcat"]["group"]

#remove java 6
package "openjdk-6-*" do
  action :purge
end


#install java 7
package "openjdk-7-jre" do
  action :install
end

package "openjdk-7-jdk" do
  action :install
end


# Get binary distro
remote_file "/tmp/#{tc7tarball}" do
    source "#{tc7url}"
    mode "0644"
    checksum "00d310f2f4e15821951e9d206af45c6b"
end

# Create group
group "#{tc7group}" do
    action :create
end

# Create user
user "#{tc7user}" do
    comment "Tomcat7 user"
    gid "#{tc7group}"
    home "#{tc7target}"
    shell "/bin/false"
    system true
    action :create
end


##install tomcat 
#package "tomcat7" do
#  action :install
#end


#service "tomcat" do
#  service_name "tomcat7"
#  supports :restart => true, :reload => true, :status => true
#  action [:enable, :start]
#end


directory "/opt/app" do
    owner "#{tc7user}"
    group "#{tc7group}"
    mode "0755"
    action :create
end

cookbook_file "/opt/app/install-webapp.tar.gz" do
  source "install-webapp.tar.gz"
end

execute "extract install-webapp" do
  user "root"
  group "root"
  command "tar -zxvf install-webapp.tar.gz && chown -R #{tc7user}:#{tc7group} /opt/app/webapp"
  cwd "/opt/app/"
end

directory "#{tc7target}/apache-tomcat-#{tc7ver}" do
    owner "#{tc7user}"
    group "#{tc7group}"
    mode "0755"
    action :create
end

# Extract
execute "tar" do
    user "#{tc7user}"
    group "#{tc7group}"
    installation_dir = "#{tc7target}"
    cwd installation_dir
    command "tar zxf /tmp/#{tc7tarball}"
    action :run
end

# Set the symlink
link "#{tc7target}/tomcat" do
    to "apache-tomcat-#{tc7ver}"
    link_type :symbolic
end

directory "/opt/app/data/tomcat7" do
	owner "#{tc7user}"
	group "#{tc7group}"
	mode "0755"
	action :create
end

directory "/var/log/tomcat7" do
	action :delete
	only_if "test -f /var/log/tomcat7"
end

link "/var/log/tomcat7" do
	to "/opt/app/data/tomcat7"
	link_type :symbolic
end

directory "/opt/app/webapp/tomcat/logs" do
	action :delete
	only_if "test -d /opt/app/webapp/tomcat/logs"
end

link "/opt/app/webapp/tomcat/logs" do
	to "/opt/app/data/tomcat7"
	link_type :symbolic
end

    template "/etc/init.d/tomcat7" do
	source "init-debian.erb"
	owner "root"
	group "root"
	mode "0755
    end
    execute "init-deb" do
	user "root"
	group "root"
	command "update-rc.d tomcat7 defaults"
	action :run
    end

# copy webapp war file
puts "Copying #{node[:webapp][:war][:snapshot_file_path]} to /opt/app/webapp/tomcat/webapps/webapp.war"
cookbook_file "/opt/app/webapp/tomcat/webapps/webapp.war" do
  owner "#{tc7user}"
  group "#{tc7group}"
  source "#{node[:webapp][:war][:snapshot_file_path]}"
end

cookbook_file "/opt/app/webapp/tomcat/lib/javaee-api-6.0-5.jar" do
  source  "webapp/javaee-api-6.0-5.jar"
end


# copy jolokia war file
cookbook_file "/opt/app/webapp/tomcat/webapps/jolokia.war" do
  owner "#{tc7user}"
  group "#{tc7group}"
  source "#{node[:webapp][:jolokia][:war][:file_path]}"
end

# copy Hazelcast Management Center application war file
cookbook_file "/opt/app/webapp/tomcat/webapps/mancenter.war" do
  owner "#{tc7user}"
  group "#{tc7group}"
  source "#{node[:webapp][:mancenter][:war][:file_path]}"
end

# create dir for hazelcast.mancenter.home. Hazelcast Management Center application needs "mancenter" dir
directory "/opt/app/webapp/mancenter" do
    owner "#{tc7user}"
    group "#{tc7group}"
    mode "0755"
    action :create
end



# Search for all webapp nodes
webapp_members = search("node", "role:#{node['role']['webapp']} AND chef_environment:#{node.chef_environment}") || []
#webapp_members << node if node.run_list.roles.include?(node['role']['webapp'])
webapp_members = webapp_members.uniq.sort_by {|x| x['ipaddress'].split(/\./).map {|i| i.to_i}}
puts "webapp Nodes: #{webapp_members.uniq}"

# Find HAProxy server IP and add it to JAVA_OPTS in /etc/default/tomcat7 file for Riak and RabbitMQ (AMQP)
haproxy_ip = ""
haproxy_nodes = search("node", "role:haproxy AND chef_environment:#{node.chef_environment}") || []

if haproxy_nodes.length > 0
  haproxy_ip = "#{haproxy_nodes.first['ipaddress']}"
end

puts "Hapoxy Public IP: #{haproxy_ip}"



# There will not be any HAProxy server when we will create webapp dev box.
# We will install Riak, RabbitMQ and webapp servers on single node.
if (haproxy_ip == "")
  haproxy_ip = "#{node.ipaddress}"
end


if (webapp_members.length == 0)
  webapp_members << node
end


template "/opt/app/webapp/conf/hazelcast.xml" do
  source "hazelcast.xml.erb"
  owner "#{tc7user}"
  group "#{tc7group}"
  mode 0644
  variables({ 'webapp_members' => webapp_members.uniq, 'haproxy_ip' => haproxy_ip })
end

template "/etc/default/tomcat7" do
  source "tomcat7.erb"
  mode 0644
  variables({
        :haproxy_ip => haproxy_ip
  })
end


directory "/opt/app" do
  owner "#{tc7user}"
  group "#{tc7group}"
  recursive true
end

script "configure_tomcat" do
	interpreter "bash"
	user "root"
	cwd "/tmp"

	code <<-EOH
	
	#stop tomcat so we can configure it
	/etc/init.d/tomcat7 stop
	rm -rf /opt/app/webapp/logs/*.log

	# add links for the legacy webapp admin
	mv /opt/app/webapp/bin/webapp.sh /opt/app/webapp/bin/webapp.refertotomcat7
	echo "/etc/init.d/tomcat7 start" > /opt/app/webapp/bin/start.sh
	echo "/etc/init.d/tomcat7 stop" > /opt/app/webapp/bin/stop.sh
	echo "/etc/init.d/tomcat7 restart" > /opt/app/webapp/bin/restart.sh
	chmod a+x /opt/app/webapp/bin/*sh

	# override tomcat default index.html file to redirect to /webapp
	echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"> <html> <head> <title>webapp Redirect</title> <meta http-equiv="REFRESH" content="0;url=/webapp/"></head> <body> </body> </html>' > /opt/app/webapp/tomcat/webapps/ROOT/index.html

	# for good measure set owner to tomcat7
	chown tomcat7:tomcat7 -R /opt/app/

	#start webapp
	/etc/init.d/tomcat7 start
  EOH

end

#Start Tomcat
execute "TomcatStart" do
	user "root"
	group "root"
	command "/etc/init.d/tomcat7 start"
	action :run
end



