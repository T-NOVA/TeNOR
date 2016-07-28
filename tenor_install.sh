#!/bin/bash

pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

show_menus() {
	clear
	echo "       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
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
    echo "       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Install TeNOR"
	echo "2. Reconfigure configuration files"
	echo "3. Register microservices"
	echo "4. Add new PoP"
	echo "5. Exit"
}

installTenor(){
	echo "Installing TeNOR..."

	echo "Checking if the Ruby version"
	ruby_version=`ruby -e "print(RUBY_VERSION < '2.2.0' ? '1' : '0' )"`
	if [[ ! `which ruby` ]]; then
        echo "Ruby is not installed, please install a version higer than 2.2.0."
        pause
        return
    fi
    if [ $ruby_version -eq 1 ]; then
        echo "Ruby version: " $RUBY_VERSION
        echo "Please, install a ruby version higher or equal to 2.2.0"
        pause
        return
    fi
    if [[ ! `which bundle` ]]; then
        echo "Bundler is not installed, please install it."
        pause
        return
    fi

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

        if [ "$folder" = "./ns-manager" ]; then
            cd default/monitoring
            bundle install --quiet
            cd ../../
        fi
        bundle install --quiet
        cd ../
    done

    configureFiles

    printf "\n\nTeNOR installation script finished\n\n"
    exit
}

configureFiles(){
    printf "\nConfigure NS/VNF modules\n"

    for folder in $(find . -type d  \( -name "ns*" -o -name "vnf*" -o -name "hot-generator" \) ); do
        printf "$folder\n"
        cd $folder
        if [ "$folder" = "./ns-manager" ]; then
            cd default/monitoring
            if [ ! -f config/config.yml ]; then
                cp config/config.yml.sample config/config.yml
            fi
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

    printf "\n\nConfiguring UI...\n\n"
    cp ui/app/config.js.sample ui/app/config.js

    printf "\n\nConfiguration done.\n\n"
    pause
}

addNewPop(){
    echo "Adding new PoP..."
    GATEKEEPER_IP=localhost
    GATEKEEPER_PASS=Eq7K8h9gpg
    GATEKEEPER_USER_ID=1
    OPENSTACK_IP=localhost
    ADMIN_TENANT_NAME=admin
    KEYSTONEPASS=password
    KEYSTONEUSER=admin
    echo "Type the Openstack IP, followed by [ENTER]:"
    read openstack_ip
    if [ -z "$openstack_ip" ]; then openstack_ip=$OPENSTACK_IP; fi

    echo "Type the Openstack admin name, followed by [ENTER]:"
    read keystoneUser
    if [ -z "$keystoneUser" ]; then keystoneUser=$KEYSTONEUSER; fi

    echo "Type the Openstack admin password, followed by [ENTER]:"
    read keystonePass
    if [ -z "$keystonePass" ]; then keystonePass=$KEYSTONEPASS; fi

    echo "Type the Openstack admin tenant name, followed by [ENTER]:"
    read admin_tenant_name
    if [ -z "$admin_tenant_name" ]; then admin_tenant_name=$ADMIN_TENANT_NAME; fi

    tokenId=$(curl -XPOST http://$GATEKEEPER_IP:8000/token/ -H "X-Auth-Password:$GATEKEEPER_PASS" -H "X-Auth-Uid:$GATEKEEPER_USER_ID" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["token"]["id"]')
    curl -X POST http://$GATEKEEPER_IP:8000/admin/dc/ \
    -H 'X-Auth-Token: '$tokenId'' \
    -d '{"msg": "PoP Testbed", "dcname":"default", "adminid":"'$keystonePass'","password":"'$keystoneUser'", "extrainfo":"pop-ip='$OPENSTACK_IP' tenant-name='$admin_tenant_name' keystone-endpoint=http://'$OPENSTACK_IP':35357/v2.0 orch-endpoint=http://'$OPENSTACK_IP':8004/v1 compute-endpoint=http://'$OPENSTACK_IP':8774/v2.1 neutron-endpoint=http://'$OPENSTACK_IP':9696/v2.0"}'

    pause
}

registerMicroservice(){
    echo "Register new microservice..."
    echo "No implemented yet!."
    pause
}

read_options(){

    if [ -n "$1" ]; then
        choice=$1
    else
        local choice
	    read -p "Enter choice [ 1 - 5 ] " choice
        echo "Not defined"
    fi

	case $choice in
		1) installTenor ;;
		2) configureFiles ;;
		3) registerMicroservice ;;
		4) addNewPop ;;
		5) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}

# ----------------------------------------------
# Step #3: Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP

# -----------------------------------
# Step #4: Main logic - infinite loop
# ------------------------------------

while true
do
	show_menus
	read_options $1
done

