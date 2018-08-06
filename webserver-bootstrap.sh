#!/usr/bin/env bash
TOMCAT_VERSION="8.0.53"

# update apt-get
echo "### Updating Apt"
apt-get -y update
apt-get -u upgrade

# Install java
echo "### Installing Java"
apt-get -y install default-jdk

# Add user/group 
echo "### Adding Tomcat user/group"
groupadd tomcat
useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

# download tomcat 8
echo "### Download and install Tomcat 8"
mkdir -p ~/tmp
cd ~/tmp
wget -q http://mirror.reverse.net/pub/apache/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

#create tomcat dir and unarchive
mkdir /opt/tomcat
tar xzf ./apache-tomcat-$TOMCAT_VERSION.tar.gz -C /opt/tomcat --strip-components=1
rm ./apache-tomcat-$TOMCAT_VERSION.tar.gz


#set needed permissions
cd /opt/tomcat
chgrp -R tomcat conf
chmod g+rwx conf
chmod g+r conf/*
chown -R tomcat work/ temp/ logs/ webapps/

#set Java Home Var
echo "### Setting Javahome"
export JAVA_HOME=`update-alternatives --config java | awk -F: '{print $2}' | tr -ds ' ' '\n'`
echo $JAVA_HOME


#install upstart script
cat > /etc/init/tomcat.conf << "EOF"
description "Tomcat Server"

  start on runlevel [2345]
  stop on runlevel [!2345]
  respawn
  respawn limit 10 5

  setuid tomcat
  setgid tomcat

  env CATALINA_HOME=/opt/tomcat


  # Modify these options as needed
  env JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"
  env CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

  exec $CATALINA_HOME/bin/catalina.sh run

  # cleanup temp directory after stop
  post-stop script
    rm -rf $CATALINA_HOME/temp/*
  end script

EOF
#reload and start tomcat
initctl reload-configuration
initctl start tomcat

#Add a user to tomcat-users.xml
cat > /opt/tomcat/conf/tomcat-users.xml << "EOF"
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<!--
  NOTE:  By default, no user is included in the "manager-gui" role required
  to operate the "/manager/html" web application.  If you wish to use this app,
  you must define such a user - the username and password are arbitrary. It is
  strongly recommended that you do NOT use one of the users in the commented out
  section below since they are intended for use with the examples web
  application.
-->
<!--
  NOTE:  The sample user and role entries below are intended for use with the
  examples web application. They are wrapped in a comment and thus are ignored
  when reading this file. If you wish to configure these users for use with the
  examples web application, do not forget to remove the <!.. ..> that surrounds
  them. You will also need to set the passwords to something appropriate.
-->
  <role rolename="manager-script"/>
  <role rolename="admin-gui"/>
  <user username="tomcat" password="tomcat" roles="manager-script,admin-gui"/>
</tomcat-users>
EOF

#restart tomcat
initctl restart tomcat

# clean up apt 
echo "### Performing Clean Up"
apt-get autoremove -y
apt-get clean
