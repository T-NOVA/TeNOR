root = ::File.dirname(__FILE__)
require ::File.join(root, 'main')

run TnovaManager.new

map('/configs') { run ServiceConfigurationController }
map('/gatekeeper') { run GatekeeperController }
map('/elastic') { run LoggerController }
map('/network-services') { run Catalogue }
map('/ns-instances') { run NsProvisionerController }
map('/ns-instances/scaling') { run ScalingController }
map('/vnf-provisioning') { run VnfProvisionerController }
map('/vnfs') { run VNFCatalogueController }
map('/accounting') { run AccountingController }
map('/ns-monitoring') { run NSMonitoringController }
map('/instances') { run MonitoringController }

