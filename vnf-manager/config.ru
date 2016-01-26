#\ -p 4567

root = ::File.dirname(__FILE__)
require ::File.join(root, 'main')

run OrchestratorVnfManager.new
