#!/bin/bash

echo ""
echo "       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo,. ..:kMMMMMMMMMMMMMMMMMMMMMM
       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk    .    .NMMMMMMMMMMMMMMMMMMMM
       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0    OMM:   .MMMMMMMMMMMMMMMMMMMM
       MMMMMMW.         ,x        0X    ;MMM.   oM;   .MMMK    OM.     ..;oNMMMMMMM
       MMMMMMW'..    ...cx    ....KK     dMM.   lM.   ;MMMN    dM.   .,.    OMMMMMM
       MMMMMMMMMM.   cMMMx    XMMMMK      0M.   lM'   ,MMMX    kM.   cMMl   .MMMMMM
       MMMMMMMMMM.   cMMMx    lddkMK      .N.   lMd    XMMo    NM.   cMN,   ;MMMMMM
       MMMMMMMMMM.   cMMMx       'MK    '  ;.   lMM;   .c;    OMM.    .   .oWMMMMMM
       MMMMMMMMMM.   cMMMx    0XXNMK    0;      lMMMx'      :KMMM.   ..   kMMMMMMMM
       MMMMMMMMMM.   cMMMx    XMMMMK    0W.     lMNNNNXOkk0NNNNWM.   cN.   dMMMMMMM
       MMMMMMMMMM.   cMMMx    ....XK    0MX.    lMocccccccccccc0M.   cMX    oMMMMMM
       MMMMMMMMMM,...oMMMk........XX....KMM0....dMxooooooooooooKM'...oMM0....dMMMMM
       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"

printf "\n\nStarting TeNOR installation script\n\n"

RAILS_ENV=development
TENOR_IP="127.0.0.1"
MONGODB_IP="127.0.0.1:27017"
GATEKEEPER="127.0.0.1:8000"
DNS_SERVER="8.8.8.8"
LOGSTASH_ADDRESS="127.0.0.1:5228"

echo "Type the IP where is installed TeNOR, followed by [ENTER]:"
read tenor_ip
if [ -z "$tenor_ip" ]; then tenor_ip=$TENOR_IP; fi

echo "Type the IP:PORT (xxx.xxx.xxx.xxx:xxxx) where is installed the MongoDB, followed by [ENTER]:"
read mongo_ip
if [ -z "$mongo_ip" ]; then mongo_ip=$MONGODB_IP; fi

echo "Type the IP:PORT (xxx.xxx.xxx.xxx:xxxx) where is installed Gatekeeper, followed by [ENTER]:"
read gatekeeper
if [ -z "$gatekeeper" ]; then gatekeeper=$GATEKEEPER; fi

echo "Type the IP of the DNS server, followed by [ENTER]:"
read dns
if [ -z "$dns" ]; then dns=$DNS_SERVER; fi

echo "Type the IP:PORT (xxx.xxx.xxx.xxx:xxxx) where is installed Logstash, followed by [ENTER]:"
read logstash_address
if [ -z "$logstash_address" ]; then logstash_address=$LOGSTASH_ADDRESS; fi

logstash_host=${logstash_address%%:*}
logstash_port=${logstash_address##*:}

printf "\nBundle install of each NS/VNF Module\n"

declare -a tenor_ns_url=("ns_manager" "ns_provisioner" "nsd_validator" "ns_monitoring" "ns_catalogue" "sla_enforcement" )
declare -a tenor_vnf_url=("vnf_manager" "vnf_provisioner" "vnfd_validator" "vnf_monitoring" "vnf_catalogue" )

bundle install --quiet

for folder in $(find . -type d \( -name "ns*" -o -name "vnf*" -o -name "hot-generator" \) ); do
	printf "$folder\n"
	cd $folder
	bundle install --quiet
	cd ../
done

printf "\nConfigure NS/VNF modules\n"

for folder in $(find . -type d  \( -name "ns*" -o -name "vnf*" -o -name "hot-generator" \) ); do
	printf "$folder\n"
	cd $folder
	if [ "$folder" = "./ns-manager" ]; then
	    cd default/monitoring
	    if [ ! -f config/config.yml ]; then
	        cp config/config.yml.sample config/config.yml
	    fi
	    bundle install --quiet
	    cd ../../
	fi

	if [ ! -f config/config.yml ]; then
	    printf "Copy Config\n"
	    cp config/config.yml.sample config/config.yml
        sed -i -e 's/\(logstash_host:\).*/\1 '$logstash_host'/' config/config.yml
        sed -i -e 's/\(logstash_port:\).*/\1 '$logstash_port'/' config/config.yml
        sed -i -e 's/\(dns_server:\).*/\1 '$dns'/' config/config.yml
        for i in "${tenor_ns_url[@]}"
        do
            sed  -i -e  's/\('$i':\).*\:\(.*\)/\1 '$tenor_ip':\2/' config/config.yml
        done
        for i in "${tenor_vnf_url[@]}"
        do
            sed  -i -e  's/\('$i':\).*\:\(.*\)/\1 '$tenor_ip':\2/' config/config.yml
        done
    fi
    if [ -f config/mongoid.yml.sample ] &&  [ ! -f config/mongoid.yml ]; then
        printf "Copy Mongo Config\n"
        cp config/mongoid.yml.sample config/mongoid.yml
        sed -i -e 's/127.0.0.1:27017/'$mongo_ip'/' config/mongoid.yml
    fi
    if [ -f config/database.yml.sample ] &&  [ ! -f config/database.yml ]; then
        printf "Copy Cassandra Config\n"
        cp config/database.yml.sample config/database.yml
    fi
    cd ../
done

printf "\n\nTeNOR installation script finished\n\n"
