#\ -p 4567

root = ::File.dirname(__FILE__)
require ::File.join(root, 'main')

run VNFManager.new

map('/vnfs') { run Catalogue }
map('/modules') { run ServiceConfiguration }
map('/vnf-monitoring') { run Monitoring }
map('/vnf-provisioning') { run Provisioning }
map('/vnf-instances/scaling') { run Scaling }
