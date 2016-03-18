#orchestrator: bundle exec rake start

#NS Manager dependencies
ns_manager: sleep 6; sh -c 'cd ns-manager && exec rake start'
ns_catalogue: sleep 6; sh -c 'cd ns-catalogue && exec rake start'
nsd_validator: sleep 6; sh -c 'cd nsd-validator && exec rake start'
ns_provisioning: sleep 6; sh -c 'cd ns-provisioning && exec rake start'
ns_inst_repo: sleep 6; sh -c 'cd ns-instance-repository && exec rake start'
ns_monitoring: sleep 6; sh -c 'cd ns-monitoring && exec rake start'
ns_monitoring_repo: sleep 6; sh -c 'cd ns-monitoring-repository && exec rake start'

#VNF Manager dependencies
vnf_manager: sleep 6; sh -c 'cd vnf-manager && exec rake start'
vnf_catalogue: sleep 6; sh -c 'cd vnf-catalogue && exec rake start'
vnfd_validator: sleep 6; sh -c 'cd vnfd-validator && exec rake start'
vnf_provisioning: sleep 6; sh -c 'cd vnf-provisioning && exec rake start'
vnf_monitoring: sleep 6; sh -c 'cd vnf-monitoring && exec rake start'
vnf_monitoring_repo: sleep 6; sh -c 'cd vnf-monitoring-repository && exec rake start'
hot_generator: sleep 6; sh -c 'cd hot-generator && exec rake start'

