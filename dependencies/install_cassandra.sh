#!/bin/bash

cassandra_version="3.7"
logstash_version="2.4.0"
elasticsearch_version="2.4.0"

echo "input {
  stdin{}
  tcp {
    port => 9999
    codec => json_lines
  }
  udp {
    port => 5229
    codec => json_lines
  }
}
output {
  elasticsearch {
	host => localhost
	protocol => http
  }
  stdout { codec => rubydebug }
}
" > logstash.conf


echo "Installing Java..."
sudo apt-add-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer

echo "Installing Cassandra"

wget http://mirrors.fe.up.pt/pub/apache/cassandra/$cassandra_version/apache-cassandra-$cassandra_version-bin.tar.gz
tar -zxvf apache-cassandra-$cassandra_version-bin.tar.gz
rm apache-cassandra-$cassandra_version-bin.tar.gz

ip_address=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
#edit config file
sed -i -e 's/\(start_rpc:\).*/\1 true/' apache-cassandra-$cassandra_version/conf/cassandra.yaml
sed -i -e 's/\(rpc_address:\).*/\1 '$ip_address'/' apache-cassandra-$cassandra_version/conf/cassandra.yaml
#start_rpc: true  => line 445
#rpc_address: 172.16.6.29 => line 475
#nano apache-cassandra-2.2.4/conf/cassandra.yaml

#load schema
#apache-cassandra-2.2.4/bin/cqlsh localhost 9042 -f ns_schema.txt

#start cassandra
#apache-cassandra-2.2.4/bin/cassandra

echo "Installation of Cassandra done. Start with the command: apache-cassandra-$cassandra_version/bin/cassandra -f."

echo "And remember to load the Schema with: apache-cassandra-$cassandra_version/bin/cqlsh localhost 9042 -f db/schema.txt"

echo "Installing logstash"

wget https://download.elastic.co/logstash/logstash/logstash-$logstash_version.tar.gz
tar -zxvf logstash-$logstash_version.tar.gz
rm logstash-$logstash_version.tar.gz

echo "Installation of Logstash done. Start with the command: logstash-$logstash_version/bin/bin/logstash agent -f logstash.conf."


echo "Installing elasticsearch"

wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$elasticsearch_version/elasticsearch-$elasticsearch_version.tar.gz
tar -zxvf elasticsearch-$elasticsearch_version.tar.gz
rm elasticsearch-$elasticsearch_version.tar.gz

echo "Installation of ElasticSearch done. Start with the command: elasticsearch-$elasticsearch_version/bin/elasticsearch."