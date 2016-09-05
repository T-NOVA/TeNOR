## 0.2.0
- Refactor code.
- Fix NS Provisioning when choose a Public Network Id.
- Fix installation script when new PoP is added.
- Internal TeNOR modules are registered automatically. Only externals (mAPI, WICM, Gatekeeper) should be included using loadModules.sh.
- Changed Lifecycle events for PublicIPs. When multi publicIps are provided, the Events are sent to the correct host specified in the lifecycle events field.
- Scaling activated. The scaling_in_out field in the VNFD is used for create a AutoScalingGroup.

## 0.1.0
- Included a dummy NSD and VNFD in the NSD/VNFD Validators for test TeNOR.
- Initial release.