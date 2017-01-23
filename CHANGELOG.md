## 0.12.0
- NS provisioning: fix unreachable openstack when login.
- UI: Improved Monitoring scroll metrics. Included threshold in NS monitoring graph.
- UI: included statistics table.
- Handle Errno::ECONNRESET in NS Manager when calling VNF Manager.
- Improved logs.
- UI: Select specific PoP for each VNF for deploy.
- NS Manager/Provisioning supports placement for VNF.
- Refactor NS/VNF Monitoring Repositories.
- Refactor Provisioning.

## 0.11.1
- Fix NS Provisioning Hash.
- Updated Descriptor Samples.
- Updated Cassandra Driver to official.
- Fix deletion.

## 0.11.0
- Finished some missing tests.
- Netfloc support finished.
- Monitoring/SLA updates.
- Added Netfloc and WICM in PoP add modal.
- Updated some docs.
- Fix hot generator when cloud init is disabled.

## 0.10.0
- Included Compute api v2
- Provisioning fixes. Handling errors when Auth and flavor errors occurs.
- Updated Gemfiles for Monitoring.
- Fixed autoscaling using the assurance parameters.
- Saving monitoring per VDU.
- Fix Scaling forwarding.
- Fix registration of modules.

## 0.9.0
- Refactor. Removed unused files and functions.
- Hide credentials from logs.
- Implemented missing WICM calls.
- UI VNFD JSON editor.
- UI included progress bar in instance status
- Calculation of creation time of each resource in a stack. Saved in the VNFR.
- Updated Dockerfile and Vagrant according last updates.

## 0.8.0
- Changed authentication method. No external entity is required for authentication.
- Authentication between modules enabled when environment is production using JWT.
- Refactors in Provisioning.
- Included Travis-CI.
- Fixes in UI.
- VNFR has a correct reference to NSR.
- Included End-to-end script for tests.

## 0.7.1
- Exchanging tokens instead of user/pass between NSProvisioner and VNFManager. This fixes the bug with Keystone v3.

## 0.7.0
- Non admin users can use TeNOR. Using already created flavors inside Openstack.
- Keystone v3 available.
- Fixed unauhtorized behaviour in the UI. Solve #123
- UI: When a PoP is added, it's possible to select though the available API versions.
- Fix mongoid array problems.
- Changed log file size to 64mb.

## 0.6.1
- DNS as array. You can specify multiple DNS when a PoP is added.
- Updated Monitoring. Implemented and included SLA management and Expression Evaluator in NS Monitoring.
- Implemented delete method for remove monitoring data when instance is removed.
- NS Provisioning improved.
- Implemented autoscaling.
- Fix responses errors.
- Updated tests.

## 0.6.0
- UI Modal with form that allows to upload VNFDs and NSDs using a JSON file.
- New version of Scaling, create a new heat template without using AutoScalingGroup template. AutoscalingGroup removes arbitrarily the instances in the scale_in.
- Migration from Logstash to Fluentd. See Specific pull request for more info.
- Updated UI logs in order to read the Fluentd logs.
- Updated Log messages.
- Code refactor. Beautification and simplification.
- NS provisioning instantiation splited in functions. Better error handling.
- The NS manager receives the PoP registration and test the credentials before save the PoP into Gatekeeper.

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
