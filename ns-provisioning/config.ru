root = ::File.dirname(__FILE__)
require ::File.join(root, 'main')

run NsProvisioning.new

map('/ns-instances') { run Provisioner }
map('/ns-instances/scaling') { run Scaling }