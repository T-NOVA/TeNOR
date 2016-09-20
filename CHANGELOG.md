## 0.4.2
- Handle Errno::EHOSTUNREACH for mAPI when not available.
- VNF Provisioning with infinite timeout.
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