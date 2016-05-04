root = ::File.dirname(__FILE__)
require ::File.join(root, 'main')

run VnfProvisioning.new

map('/vnf-provisioning') { run Provisioning }
map('/vnf-instances/scaling') { run Scaling }