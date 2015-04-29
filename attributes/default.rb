default.webapp.home = "/opt/app/webapp"
default.webapp.tomcat.user = "tomcat7" 
default.webapp.tomcat.group = "tomcat7"
default.webapp.war.snapshot_file_path="webapp/webapp.war"
default['role']['webapp'] = "webapp"
default.webapp.java.version = "7"
default.webapp.riak.seed_ip = ""
default.webapp.rabbitmq.seed_ip = ""
default.webapp.rabbitmq.default_user = 'guest'
default.webapp.rabbitmq.default_pass = ''
default.webapp.tomcat.target = "/opt/app/webapp"
default.webapp.tomcat.version = "7.0.42"
default.webapp.tomcat.home = "/opt/app/webapp/tomcat"

#Setting default JAVA_OPS parameters
default[:webapp][:java][:java_opts] = "-server -d64 -Djava.awt.headless=true -Xms1024M -Xmx3000M -DHOSTNAME=`hostname` -Dhazelcast.logging.type=slf4j -Dhazelcast.jmx=true -Driak.pb.port=8087 -Dlogback.configurationFile=$webapp_HOME/conf/logback.xml -Dhazelcast.enterprise.license.key='GJKCFO9NLHA4340U177111R130Y01W' -DauthN=authentication-scheme-2 -Dspring.amqp.port=5672 -Dspring.amqp.vhost=/ -Djava.net.preferIPv4Stack=true -Dwebapp_HOME=$webapp_HOME -DwebappPersistence=riak -DclientPersistence=riak -XX:PermSize=512M -XX:MaxPermSize=512M"

#Setting default CATALINA_OPTS parameters
default[:webapp][:tomcat][:catalina_opts] = "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=`hostname` -Dhazelcast.mancenter.home='/opt/app/webapp/mancenter'"


#Setting for Jolokia 
default.webapp.jolokia.war.file_path= "jolokia/jolokia-war-1.0.5.war"


#Setting for Hazelcast Management Center 
default.webapp.mancenter.war.file_path= "hazelcast-2.4-ee/mancenter.war"

# Centralized logging settings. 
# If default.centralized_logging.enable=true and default.centralized_logging.node is empty then recipe will use HAProxy node as centralized_logging.node
#default.centralized_logging.enable=false
#default.centralized_logging.node=""


#Setting environment related settings here
case node.chef_environment

when 'webapp-prod'
	default.centralized_logging.enable=true
	default.centralized_logging.node=""
	default.centralized_logging.port=""
    default.webapp.java.java_opts="-server -d64 -Djava.awt.headless=true -Xms1024M -Xmx3000M -DHOSTNAME=`hostname` -Dhazelcast.logging.type=slf4j -Dhazelcast.jmx=true -Driak.pb.port=8087 -Dlogback.configurationFile=$webapp_HOME/conf/logback.xml -DauthN=authentication-scheme-3 -Dspring.amqp.port=5672 -Dspring.amqp.vhost=/ -Djava.net.preferIPv4Stack=true -Dwebapp_HOME=$webapp_HOME -DwebappPersistence=riak -DclientPersistence=riak -XX:PermSize=512M -XX:MaxPermSize=512M" 

else
	default.centralized_logging.enable=false
	default.centralized_logging.port="514"
end

