#!/bin/bash

declare tenor_ip
declare mongo_ip
declare gatekeeper
declare logstash_address
declare cassandra_address
CURRENT_PROGRESS=0
bold=$(tput bold)
normal=$(tput sgr0)

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
	echo "5. Remove PoP"
	echo "6. Inserting sample VNF and NS"
	echo "7. Exit"
}
function delay()
{
    sleep 0.2;
}
function progress()
{
    PARAM_PROGRESS=$1;
    PARAM_STATUS=$2;

    if [ $CURRENT_PROGRESS -le 0 -a $PARAM_PROGRESS -ge 0 ]  ; then echo -ne "[..........................] (0%)  $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 5 -a $PARAM_PROGRESS -ge 5 ]  ; then echo -ne "[#.........................] (5%)  $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 10 -a $PARAM_PROGRESS -ge 10 ]; then echo -ne "[##........................] (10%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 15 -a $PARAM_PROGRESS -ge 15 ]; then echo -ne "[###.......................] (15%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 20 -a $PARAM_PROGRESS -ge 20 ]; then echo -ne "[####......................] (20%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 25 -a $PARAM_PROGRESS -ge 25 ]; then echo -ne "[#####.....................] (25%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 30 -a $PARAM_PROGRESS -ge 30 ]; then echo -ne "[######....................] (30%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 35 -a $PARAM_PROGRESS -ge 35 ]; then echo -ne "[#######...................] (35%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 40 -a $PARAM_PROGRESS -ge 40 ]; then echo -ne "[########..................] (40%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 45 -a $PARAM_PROGRESS -ge 45 ]; then echo -ne "[#########.................] (45%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 50 -a $PARAM_PROGRESS -ge 50 ]; then echo -ne "[##########................] (50%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 55 -a $PARAM_PROGRESS -ge 55 ]; then echo -ne "[###########...............] (55%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 60 -a $PARAM_PROGRESS -ge 60 ]; then echo -ne "[############..............] (60%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 65 -a $PARAM_PROGRESS -ge 65 ]; then echo -ne "[#############.............] (65%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 70 -a $PARAM_PROGRESS -ge 70 ]; then echo -ne "[###############...........] (70%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 75 -a $PARAM_PROGRESS -ge 75 ]; then echo -ne "[#################.........] (75%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 80 -a $PARAM_PROGRESS -ge 80 ]; then echo -ne "[####################......] (80%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 85 -a $PARAM_PROGRESS -ge 85 ]; then echo -ne "[#######################...] (90%) $PARAM_PHASE \r"  ; delay; fi;
    if [ $CURRENT_PROGRESS -le 90 -a $PARAM_PROGRESS -ge 90 ]; then echo -ne "[##########################] (100%) $PARAM_PHASE \r" ; delay; fi;
    if [ $CURRENT_PROGRESS -le 100 -a $PARAM_PROGRESS -ge 100 ];then echo -ne 'Done!                                            \n' ; delay; fi;

    CURRENT_PROGRESS=$PARAM_PROGRESS;

}

pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

installTenor(){
	echo "Installing TeNOR..."

	echo "Checking the Ruby version: " $RUBY_VERSION
	ruby_version=`ruby -e "print(RUBY_VERSION < '2.2.0' ? '1' : '0' )"`
	if [[ ! `which ruby` ]]; then
        echo "Ruby is not installed, please install a version higer than 2.2.0."
        pause
        return
    fi
    if [ $ruby_version -eq 1 ]; then
        ruby --version > /dev/null 2>&1
        RUBY_IS_INSTALLED=$?
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

    printf "\n\n${bold}Starting TeNOR installation... Please wait, this can take some time.${normal}\n\n"

    declare -a tenor_ns_url=("ns_manager" "ns_provisioner" "nsd_validator" "ns_monitoring" "ns_catalogue" "sla_enforcement" )
    declare -a tenor_vnf_url=("vnf_manager" "vnf_provisioner" "vnfd_validator" "vnf_monitoring" "vnf_catalogue" )

    bundle install --quiet

    max=14
    count=0
    progress 0
    array=(*/)
    for folder in "${array[@]}"; do
        #printf "$folder\n"

        if [[ "$folder" =~ ^ns-* ]] || [[ "$folder" =~ ^vnf-* ]] || [[ "$folder" =~ ^hot-* ]] || [[ "$folder" = "ui/" ]]; then
            cd $folder

            if [ "$folder" = "ns-manager/" ]; then
                cd default/monitoring
                bundle install --quiet
                cd ../../
            fi
            bundle install --quiet
            cd ../
            count=$((count+1))
            progress  $(( 100 * $count / $max )) ""
        fi
    done

    fluent-gem install fluent-plugin-mongo

    configureFiles

    printf "\n\n${bold}TeNOR installation script finished${normal}\n\n"
    exit
}

configureIps(){
    RAILS_ENV=development
    TENOR_IP="127.0.0.1"
    MONGODB_IP="127.0.0.1:27017"
    GATEKEEPER="127.0.0.1:8000"
    LOGSTASH_ADDRESS="127.0.0.1:5228"
    CASSANDRA_ADDRESS="127.0.0.1"

    echo -e "${bold}Please, insert the IPs and ports used in each service. In the case you have installed everything locally (localhost) you can press [ENTER] without write anything${normal}.\n\n"


    echo "Type the IP where is installed TeNOR, followed by [ENTER]:"
    read tenor_ip
    if [ -z "$tenor_ip" ]; then tenor_ip=$TENOR_IP; fi

    echo "Type the IP:PORT (xxx.xxx.xxx.xxx:xxxx) where is installed the MongoDB, followed by [ENTER]:"
    read mongo_ip
    if [ -z "$mongo_ip" ]; then mongo_ip=$MONGODB_IP; fi

    echo "Type the IP:PORT (xxx.xxx.xxx.xxx:xxxx) where is installed Gatekeeper, followed by [ENTER]:"
    read gatekeeper
    if [ -z "$gatekeeper" ]; then gatekeeper=$GATEKEEPER; fi

    echo "Type the IP (xxx.xxx.xxx.xxx) where is installed Cassandra, followed by [ENTER]:"
    read cassandra_address
    if [ -z "$cassandra_address" ]; then cassandra_address=$CASSANDRA_ADDRESS; fi

    mongodb_host=${mongo_ip%%:*}
    mongodb_port=${mongo_ip##*:}

    mkdir fluentd
    cat >fluentd/fluent.conf <<EOL
        # In v1 configuration, type and id are @ prefix parameters.
    # @type and @id are recommended. type and id are still available for backward compatibility

    ## built-in TCP input
    ## $ echo <json> | fluent-cat <tag>
    <source>
      @type forward
      @id forward_input
    </source>

    ## built-in UNIX socket input
    #<source>
    #  @type unix
    #</source>

    # HTTP input
    # http://localhost:8888/<tag>?json=<json>
    <source>
      @type http
      @id http_input

      port 8888
    </source>

    ## File input
    ## read apache logs with tag=apache.access
    #<source>
    #  @type tail
    #  format apache
    #  path /var/log/httpd-access.log
    #  tag apache.access
    #</source>

    # Listen HTTP for monitoring
    # http://localhost:24220/api/plugins
    # http://localhost:24220/api/plugins?type=TYPE
    # http://localhost:24220/api/plugins?tag=MYTAG
    <source>
      @type monitor_agent
      @id monitor_agent_input

      port 24220
    </source>

    # Listen DRb for debug
    <source>
      @type debug_agent
      @id debug_agent_input

      bind 127.0.0.1
      port 24230
    </source>

    ## match tag=debug.** and dump to console
    <match debug.**>
      @type stdout
      @id stdout_output
    </match>

    <match **>
      @type mongo
      host 127.0.0.1
      port 27017
      database fluentd
      #collection tenor_logs
      tag_mapped

      # for capped collection
      capped
      capped_size 1024m

      # authentication
      # user mongouser
      # password mongouser_pass

      # flush
      flush_interval 10s
    </match>

EOL

}
configureFiles(){
    printf "\nConfiguring NS/VNF modules\n\n"

    configureIps

    rm **/config/config.yml

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
            cp config/config.yml.sample config/config.yml
        fi
        if [ -f config/mongoid.yml.sample ] &&  [ ! -f config/mongoid.yml ]; then
            cp config/mongoid.yml.sample config/mongoid.yml
        fi
        if [ -f config/database.yml.sample ] &&  [ ! -f config/database.yml ]; then
            cp config/database.yml.sample config/database.yml
        fi

        sed -i -e 's/\(logstash_host:\).*/\1 '$logstash_host'/' config/config.yml
        sed -i -e 's/\(logstash_port:\).*/\1 '$logstash_port'/' config/config.yml
        sed -i -e 's/\(gatekeeper:\).*/\1 '$gatekeeper'/' config/config.yml
        for i in "${tenor_ns_url[@]}"; do
            sed  -i -e  's/\('$i':\).*\:\(.*\)/\1 '$tenor_ip':\2/' config/config.yml
        done
        for i in "${tenor_vnf_url[@]}"; do
            sed  -i -e  's/\('$i':\).*\:\(.*\)/\1 '$tenor_ip':\2/' config/config.yml
        done

        if [ -f config/mongoid.yml ]; then
            sed -i -e 's/127.0.0.1:27017/'$mongo_ip'/' config/mongoid.yml
        fi
        if [ -f config/database.yml ]; then
            sed -i -e 's/127.0.0.1:27017/'$cassandra_address'/' config/database.yml
        fi

        cd ../
    done

    printf "\nConfiguring UI...\n\n"
    cp ui/app/config.js.sample ui/app/config.js

    printf "\nConfiguration done.\n\n"
    pause
}

addNewPop(){
    echo "Adding new PoP..."
    GATEKEEPER_HOST=localhost:8000
    GATEKEEPER_PASS=Eq7K8h9gpg
    GATEKEEPER_USER_ID=1
    OPENSTACK_NAME=default
    OPENSTACK_IP=localhost
    ADMIN_TENANT_NAME=admin
    KEYSTONEPASS=password
    KEYSTONEUSER=admin
    OPENSTACK_DNS=8.8.8.8

    echo "Type the Gatekeeper hosts (localhost:8000), followed by [ENTER]:"
    read gatekeeper_host
    if [ -z "$gatekeeper_host" ]; then gatekeeper_host=$GATEKEEPER_HOST; fi

    echo "Type the Openstack name, followed by [ENTER]:"
    read openstack_name
    if [ -z "$openstack_name" ]; then openstack_name=$OPENSTACK_NAME; fi

    echo "Type the Openstack IP, followed by [ENTER]:"
    read openstack_ip
    if [ -z "$openstack_ip" ]; then openstack_ip=$OPENSTACK_IP; fi

    echo "Type the Openstack admin name, followed by [ENTER]:"
    read keystoneUser
    if [ -z "$keystoneUser" ]; then keystoneUser=$KEYSTONEUSER; fi

    echo "Type the Openstack admin password, followed by [ENTER]:"
    read -s keystonePass
    if [ -z "$keystonePass" ]; then keystonePass=$KEYSTONEPASS; fi

    echo "Type the Openstack admin tenant name, followed by [ENTER]:"
    read admin_tenant_name
    if [ -z "$admin_tenant_name" ]; then admin_tenant_name=$ADMIN_TENANT_NAME; fi

    echo "Type the Openstack DNS IP, followed by [ENTER]:"
    read openstack_dns
    if [ -z "$openstack_dns" ]; then openstack_dns=$OPENSTACK_DNS; fi

    tokenId=$(curl -XPOST http://$gatekeeper_host/token/ -H "X-Auth-Password:$GATEKEEPER_PASS" -H "X-Auth-Uid:$GATEKEEPER_USER_ID" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["token"]["id"]')
    curl -X POST http://$gatekeeper_host/admin/dc/ \
    -H 'X-Auth-Token: '$tokenId'' \
    -d '{"msg": "PoP Testbed", "dcname":"'$openstack_name'", "adminid":"'$keystoneUser'","password":"'$keystonePass'", "extrainfo":"pop-ip='$openstack_ip' tenant-name='$admin_tenant_name' keystone-endpoint=http://'$openstack_ip':35357/v2.0 orch-endpoint=http://'$openstack_ip':8004/v1 compute-endpoint=http://'$openstack_ip':8774/v2.1 neutron-endpoint=http://'$openstack_ip':9696/v2.0 dns='$openstack_dns'"}'

    pause
}

conn_openstack() {
    tokenId=$(curl -XPOST $1":35357/v2.0" -d "" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["token"]["id"]')

}

removePop() {
    echo "Removing PoP..."
    gatekeeper_host=10.10.1.63:8000
    GATEKEEPER_PASS=Eq7K8h9gpg
    GATEKEEPER_USER_ID=1

    tokenId=$(curl -XPOST http://$gatekeeper_host/token/ -H "X-Auth-Password:$GATEKEEPER_PASS" -H "X-Auth-Uid:$GATEKEEPER_USER_ID" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["token"]["id"]')
    options=$(curl -XGET http://$gatekeeper_host/admin/dc/ -H 'X-Auth-Token: '$tokenId'' | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["dclist"]')

    echo "Type the PoP Id, followed by [ENTER]:"
    read pop_id

    popInfo=$(curl -XGET http://$gatekeeper_host/admin/dc/$pop_id -H 'X-Auth-Token: '$tokenId'' | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["info"]')
    echo "PoP to remove: "

    echo "Are you sure you want to remove this PoP (y/n)?, followed by [ENTER]:"
    read remove

    if [ "$remove" = "y" ]; then
      echo "Removing PoP..."
      curl -XDELETE http://$gatekeeper_host/admin/dc/$pop_id -H 'X-Auth-Token: '$tokenId''
    fi

    pause
}

registerMicroservice(){
    echo "Register new microservice..."
    echo "No implemented yet!."
    pause
}

insertSamples(){
    echo "Inserting VNF..."
    curl -XPOST localhost:4000/vnfs -H "Content-Type: application/json" --data-binary @vnfd-validator/assets/samples/vnfd_example.json
    vnf_id=$(curl -XGET localhost:4000/vnfs | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["vnfd"]["id"]')
    echo "Inserting NS..."
    curl -XPOST localhost:4000/network-services -H "Content-Type: application/json" --data-binary @nsd-validator/assets/samples/nsd_example.json
    ns_id=$(curl -XGET localhost:4000/network-services | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["nsd"]["id"]')
    echo "NSD id: " $ns_id
    echo "VNFD id: " $vnf_id

    pause
}
read_options(){

    if [ -n "$1" ]; then
        choice=$1
    else
        local choice
	    read -p "${bold}Enter choice [ 1 - 7 ]${normal} " choice
    fi

	case $choice in
		1) installTenor ;;
		2) configureFiles ;;
		3) registerMicroservice ;;
		4) addNewPop ;;
		5) removePop ;;
		6) insertSamples ;;
		7) exit 0;;
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

choice=$1

while true
do
	show_menus
	read_options $choice
	exit 0
done
