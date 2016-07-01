#!/bin/bash
SESSION='nsmanager'
SESSION2='vnfmanager'
SESSION3='gatekeeper'
SESSION4='ui'

/etc/init.d/mongod start

byobu -2 new-session -d -s $SESSION3
echo "Starting Gatekeeper..."
byobu rename-window 'GK'
byobu send-keys "cd ../" C-m
byobu send-keys "go/bin/auth-utils" C-m

byobu -2 new-session -d -s $SESSION
echo "Starting NS Manager..."
byobu rename-window "NSMan"
byobu send-keys "cd TeNOR" C-m
byobu send-keys "cd ns-manager" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'LoadModules'
byobu send-keys "" C-m
byobu send-keys "sh loadModules.sh" C-m

byobu new-window -n 'Catlg'
byobu send-keys "cd ns-catalogue" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'NSDV'
byobu send-keys "cd nsd-validator" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'Prov.'
byobu send-keys "cd ns-provisioning" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'NSMon'
byobu send-keys "cd ns-monitoring" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'NSMon.Repo'
byobu send-keys "cd ns-monitoring-repository" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'M-Mon'
byobu send-keys "cd ns-manager/default/monitoring" C-m
byobu send-keys "bundle exec rake start" C-m

byobu -2 new-session -d -s $SESSION2
echo "Starting VNF Manager..."
byobu rename-window 'VNFMan'
byobu send-keys "cd vnf-manager" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'VNFCat'
byobu send-keys "cd vnf-catalogue" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'VNFDVal'
byobu send-keys "cd vnfd-validator" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'VNFProv'
byobu send-keys "cd vnf-provisioning" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'VNFMon'
byobu send-keys "cd vnf-monitoring" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'VNFMon.Repo'
byobu send-keys "cd vnf-monitoring-repository" C-m
byobu send-keys "bundle exec rake start" C-m

byobu new-window -n 'HOTGen'
byobu send-keys "cd hot-generator" C-m
byobu send-keys "bundle exec rake start" C-m

byobu -2 new-session -d -s $SESSION4
echo "Starting User Interface..."
byobu rename-window 'UI'
byobu send-keys "cd ui" C-m
byobu send-keys "grunt serve" C-m

byobu
