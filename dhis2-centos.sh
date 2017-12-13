#!/bin/bash

yum -y install epel-release

yum -y install -- \
  ansible \
  libselinux-python libsemanage-python \
  python-psycopg2 \
  vim-enhanced

ansible all -i 'localhost,' -c local -m selinux -a "state=disabled"
setenforce Permissive

yum -y install -- \
  java-1.8.0-openjdk-devel \
  nginx \
  tomcat \
  postgresql-server

systemctl enable nginx
systemctl enable tomcat
systemctl enable postgresql

postgresql-setup initdb
ansible all -i 'localhost,' -c local -m replace -a "path=/var/lib/pgsql/data/pg_hba.conf regexp='^(local\s+.*\s+peer$)' replace='\1 map=local_users'"
ansible all -i 'localhost,' -c local -m replace -a "path=/var/lib/pgsql/data/pg_hba.conf regexp='^(host\s+all\s+all\s+.*\s+)ident$' replace='\1 md5'"
ansible all -i 'localhost,' -c local -m lineinfile -a "path=/var/lib/pgsql/data/pg_ident.conf line='local_users  postgres  postgres'"
ansible all -i 'localhost,' -c local -m lineinfile -a "path=/var/lib/pgsql/data/pg_ident.conf line='local_users  root  postgres'"
ansible all -i 'localhost,' -c local -m lineinfile -a "path=/var/lib/pgsql/data/pg_ident.conf line='local_users  root  dhis'"
systemctl start postgresql && sleep 5
ansible all -i 'localhost,' -c local -m postgresql_user -a "name=dhis encrypted=yes password=\"{{ lookup('password', '/root/pg_dhis_passwd.txt chars=ascii_letters,digits') }}\""
ansible all -i 'localhost,' -c local -m postgresql_db -a "name=dhis2 owner=dhis"

install -o tomcat -g tomcat -d /opt/dhis2/
ansible all -i 'localhost,' -c local -m blockinfile -a "path=/opt/dhis2/dhis.conf owner=tomcat group=tomcat create=yes block='connection.dialect = org.hibernate.dialect.PostgreSQLDialect
connection.driver_class = org.postgresql.Driver
connection.url = jdbc:postgresql:dhis2
connection.username = dhis
connection.password = {{ lookup('password', '/root/pg_dhis_passwd.txt chars=ascii_letters,digits') }}
connection.schema = update
'"
sed -e '/^.*ANSIBLE MANAGED BLOCK$/d' -i /opt/dhis2/dhis.conf

ansible all -i 'localhost,' -c local -m lineinfile -a "path=/etc/sysconfig/tomcat line='JAVA_OPTS=\"-Djava.security.egd=file:/dev/./urandom\"'"
ansible all -i 'localhost,' -c local -m lineinfile -a "path=/etc/tomcat/tomcat.conf line='JAVA_OPTS=\"-Djava.security.egd=file:/dev/./urandom\"'"
su - tomcat -s /bin/bash -c "curl -L -o /var/lib/tomcat/webapps/ROOT.war https://www.dhis2.org/download/releases/2.28/dhis.war"
systemctl start tomcat

ansible all -i 'localhost,' -c local -m lineinfile -a "path='/etc/nginx/nginx.conf' insertafter='^[^#]\s+location\s+/\s+{' line='          proxy_pass  http://localhost:8080;' validate='nginx -c %s -t'"
ansible all -i 'localhost,' -c local -m lineinfile -a "path='/etc/nginx/nginx.conf' insertafter='^[^#]\s+proxy_pass\s+' line='          proxy_set_header  Host               \$http_host;' validate='nginx -c %s -t'"
ansible all -i 'localhost,' -c local -m lineinfile -a "path='/etc/nginx/nginx.conf' insertafter='^[^#]\s+proxy_set_header\s+Host\s+' line='          proxy_set_header  X-Forwarded-Proto  \$scheme;' validate='nginx -c %s -t'"
systemctl start nginx
