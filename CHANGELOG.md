## 0.5.1
- UI PoP view. Hide remove modal and refresh list of PoPs.
- Updated Installation Dependencies script, Dockerfile and Vagrantfile.
- UI Fix Proxy in get method. Now forwarding query params.
- Fix PoP not found in NS Provisioning.

## 0.5.0
- UI changed Grunt to Ruby Sinatra App.
- Changed Sinatra Server, Thin to Puma.
- Updated Installation scripts and README. Node and NPM removed.
- Updated Docker in order to use Invoker.
- Removed EventMachine due problems with Puma server, using ruby threads.
- NS manager and NS provisioning support a predefined PoP id inserted.
- Included Netfloc Models in Hot Generator
- Defined Scale_out lifecycle_event template. Updated scaling accordingly.
- Updated scale_examples with two VDUs, the controller VDU must not scale!
- NS manager uses Gatekeeper ids accordingly to the recent update in Gatekeeper.
- Updating UI according with the new version of Gatekeeper that has fixed the IDs removal problem.
- Updating UI included more options when a service is instantiated. The PoP id can be choosed. Service Mapping, NAP, and customer id also included.
- Included Bower_components.

## 0.4.2
- Handle Errno::EHOSTUNREACH for mAPI when not available.
- Re-login in Gatekeeper when the list of PoPs is requested. Avoid token invalid.

## 0.4.1
- Reading DNS information from PoP Info.
- Fix default tenant name, now it's used correctly.

## 0.4.0
- Fixed installation issues.
- Included DNS in tenor_install script.
- Port_Security is disabled by default due problems with some Openstack versions.
- When only one pop is defined, the vnf is deployed automatically to that pop.
- VNF provisioning allows to deploy to a specific PoP. Updated instantiation form in UI.
- NS Provisioning default tenant name specified in config file. Can be disabled. By default disabled.
- Fix grunt installaltion.
- Refactor NS Provisioning errors.
 

## 0.3.0
- UI infinite monitoring request fixed.
- Included Invoker for deployment of TeNOR.
- Included Parameter in Hot Generator
- Update Scaling for support Floating IPs. Updated Hot Generator and VNF Provisioning using Nested Templates.
- Hot Generator fixed yaml response.
- Updated Hot Generator Network in order to avoid problems with Port_Security
- Updated installation dependencies script.

## 0.2.0
- Refactor code.
- Fix NS Provisioning when choose a Public Network Id.
- Fix installation script when new PoP is added.
- Internal TeNOR modules are registered automatically. Only externals (mAPI, WICM, Gatekeeper) should be included using loadModules.sh.
- Changed Lifecycle events for PublicIPs. When multi publicIps are provided, the Events are sent to the correct host specified in the lifecycle events field.
- Scaling activated. The scaling_in_out field in the VNFD is used for create a AutoScalingGroup.
- HOT Generator accepts existing_net_id defined in the VNFD. The networks needs access to the public network.

## 0.1.0
- Included a dummy NSD and VNFD in the NSD/VNFD Validators for test TeNOR.
- Initial release.