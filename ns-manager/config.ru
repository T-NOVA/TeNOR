root = ::File.dirname(__FILE__)
require ::File.join(root, 'main')

run TnovaManager.new

map('/configs') { run ServiceConfiguration }
map('/gatekeeper') { run GatekeeperController }
map('/logs') { run LoggerController }
map('/network-services') { run NsCatalogue }
map('/ns-instances') { run NsProvisioner }
map('/ns-instances/scaling') { run NsScaling }
map('/vnf-provisioning') { run VnfProvisioner }
map('/vnfs') { run VNFCatalogue }
map('/accounting') { run AccountingController }
map('/instances') { run NsMonitoring }
