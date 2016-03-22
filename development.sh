#!/bin/bash
SESSION='nsmanager'
SESSION2='vnfmanager'

# -2: forces 256 colors, 
byobu-tmux -2 new-session -d -s $SESSION

# dev window
byobu-tmux rename-window -t $SESSION:0 'Mgt'
byobu-tmux send-keys "cd ns-manager" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION:1 -n 'Catlg'
byobu-tmux send-keys "cd ns-catalogue" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION:2 -n 'NSDV'
byobu-tmux send-keys "cd nsd-validator" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION:3 -n 'Prov.'
byobu-tmux send-keys "cd ns-provisioning" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION:4 -n 'Ins.Repo'
byobu-tmux send-keys "cd ns-instance-repository" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION:5 -n 'NSMon'
byobu-tmux send-keys "cd ns-monitoring" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION:6 -n 'NSMon.Repo'
byobu-tmux send-keys "cd ns-monitoring-repository" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION:7 -n 'M-Mon'
byobu-tmux send-keys "cd ns-manager/default/monitoring" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux -2 new-session -d -s $SESSION2

byobu-tmux new-window -t $SESSION2:0 -n 'VNFMan'
byobu-tmux send-keys "cd vnf-manager" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION2:1 -n 'VNFCat'
byobu-tmux send-keys "cd vnf-catalogue" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION2:2 -n 'VNFDVal'
byobu-tmux send-keys "cd vnfd-validator" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION2:3 -n 'VNFProv'
byobu-tmux send-keys "cd vnf-provisioning" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION2:4 -n 'VNFMon'
byobu-tmux send-keys "cd vnf-monitoring" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION2:5 -n 'VNFMon.Repo'
byobu-tmux send-keys "cd vnf-monitoring-repository" C-m
byobu-tmux send-keys "rake start" C-m

byobu-tmux new-window -t $SESSION2:6 -n 'HOTGen'
byobu-tmux send-keys "cd hot-generator" C-m
byobu-tmux send-keys "rake start" C-m

# Set default window as the dev split plane
byobu-tmux select-window -t $SESSION:0

