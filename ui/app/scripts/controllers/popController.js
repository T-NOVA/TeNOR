'use strict';

angular.module('tNovaApp')
    .controller('PoPController', function ($scope, $window, $interval, $modal, $alert, tenorService, AuthService, infrRepoService) {

        $scope.obj = {};
        $scope.obj = {data: {}, options: { mode: 'code' }};

        $scope.defaultPoP = {};
        $scope.registeredDcList = [];
        $scope.keystone_versions = [{"id": "v2.0"}, {"id": "v3"}];
        $scope.heat_versions = [{"id": "v1"}];
        $scope.compute_versions = [{"id": "v2"}, {"id": "v2.1"}];
        $scope.neutron_versions = [{"id": "v2.0"}];

        $scope.keystone_version = "v2.0"
        $scope.heat_version = "v1"
        $scope.compute_version = "v2.1"
        $scope.neutron_version = "v2.0"

        $scope.netfloc_ip = ""
        $scope.netfloc_user = "admin"
        $scope.netfloc_pass = ""

        $scope.wicm_ip = ""

        $scope.openstack_ip = "";
        $scope.infr_repo_url = undefined

        tenorService.get("modules/services/type/infr_repo").then(function (data) {
            if (data === undefined) return;
            console.log(data);
            if (data.length > 0){
                $scope.infr_repo_url = data[0].host + ":" + data[0].port;
            }
            $scope.refreshPoPList();
        });

        $scope.refreshPoPList = function () {
            tenorService.get('pops/dc').then(function (d) {
                console.log(d);
                $scope.registeredDcList = d;
                /*_.map(d.dclist, function (row, index) {
                    $scope.registeredDcList.push({
                        id: d.dcid[index],
                        name: row
                    })
                });*/
                console.log($scope.registeredDcList);
                if ($scope.infr_repo_url == undefined){
                    return;
                }

                var url = 'pop/';
                infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {
                    $scope.pops = _data;
                    $scope.availableDcList = [];
                    angular.forEach(_data, function (pop, index, array) {
                        url = pop.identifier.slice(1);
                        infrRepoService.get($scope.infr_repo_url, url).then(function (_data) {

                            var exist = _.some($scope.registeredDcList, function (c) {
                                return _data.attributes['occi.epa.popuuid'] !== c;
                            });
                            console.log(exist);
                            if (!exist) {
                                $scope.availableDcList.push(_data.attributes);
                            }
                        });
                    });
                });
            });
        };
        //$scope.refreshPoPList();

        $scope.addDialog = function (infr_repo_pop) {
            $scope.object = $scope.defaultPoP;
            console.log($scope.object);

            console.log(infr_repo_pop);
            if (infr_repo_pop !== undefined){
                $scope.object.id = infr_repo_pop['occi.epa.popuuid'];
                $scope.object.msg = infr_repo_pop['occi.epa.pop.name'];
                $scope.emptyId = true;
            }else{
                $scope.object.id = "Pop_identification";
                $scope.object.msg = "Pop_description";
            };
            /*if (id === "") {
                $scope.emptyId = true;
            }*/

            //$scope.object.id = id;
            $scope.dc_default = $scope.defaultPoP;
            $scope.openstack_ip = "";
            $scope.dc_default = {
                msg: $scope.object.msg,
                id: $scope.object.id,
                adminid: "admin",
                password: "adminpass",
                isAdmin: false,
                openstack_ip: $scope.openstack_ip,
                keystone_api: $scope.openstack_ip + ":35357/" + $scope.keystone_version,
                heat_api: $scope.openstack_ip + ":8004/v1",
                compute_api: $scope.openstack_ip + ":8774/v2.1",
                neutron_api: $scope.openstack_ip + ":9696/v2.0",
                dns: "8.8.8.8"
            };
            $modal({
                title: "Registring DC - " + $scope.object.id,
                template: "views/t-nova/modals/addPop.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.registerDc = function (obj) {
            var pop = {
                "name": obj.id,
                "user": obj.adminName,
                "host": obj.openstack_ip,
                "password": obj.adminPass,
                "tenant_name": obj.tenantName,
                "is_admin": obj.isAdmin,
                "description": obj.msg,
                "extra_info": "keystone-endpoint=http://" + obj.keystone_api + " orch-endpoint=http://" + obj.heat_api + " compute-endpoint=http://" + obj.compute_api + " neutron-endpoint=http://" + obj.neutron_api + " dns=" + obj.dns + " netfloc_ip=" + obj.netfloc_ip + " netfloc_user=" + obj.netfloc_user + " netfloc_pass=" + obj.netfloc_pass + " wicm_ip=" + obj.wicm_ip
            };
            console.log(pop);
            tenorService.post('pops/dc', pop).then(function (d) {
                console.log(d);
                $scope.defaultPoP = {};
                $alert({
                    title: "Success: ",
                    content: "PoP inserted correctly.",
                    placement: 'top',
                    type: 'success',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container',
                    duration: 5
                });
                $scope.refreshPoPList();
            }, function errorCallback(response) {
                console.log("Error");
                console.log(response);
                $scope.defaultPoP = obj;
                $alert({
                    title: "Error: ",
                    content: "PoP not created correctly.",
                    placement: 'top',
                    type: 'danger',
                    keyboard: true,
                    show: true,
                    container: '#alerts-container',
                    duration: 5
                });
            });
            this.$hide();
        };

        $scope.getPopInfo = function (pop_info) {
            $scope.popInfo = pop_info;
            $scope.jsonObj = JSON.stringify(pop_info, undefined, 4);
            $modal({
                title: "Pop - " + pop_info['id'] + " - " + pop_info['name'],
                template: "views/t-nova/modals/info/showPop.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.editPopDialog = function(pop_info){
            $scope.obj.data = pop_info;
            $modal({
                title: "Pop - " + pop_info['id'] + " - " + pop_info['name'],
                template: "views/t-nova/modals/editPop.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.updateDc = function(pop_info){
            console.log(pop_info);
            tenorService.put('pops/dc/' +pop_info.id, pop_info).then(function (d) {
                console.log(d);
            });
            this.$hide();
        };

        $scope.removePopDialog = function (id) {
            $scope.itemToDeleteId = id;
            $modal({
                title: "Are you sure you want to delete this item?",
                template: "views/t-nova/modals/delete.html",
                show: true,
                scope: $scope,
            });
        };

        $scope.deleteItem = function (popId) {
            tenorService.delete('pops/dc/' + popId).then(function (data) {
                console.log(data);
                $scope.refreshPoPList();
            });
            this.$hide();
        };

    }).controller('PoPModalController', function ($scope, $window, $interval, $modal, $alert, tenorService, AuthService, infrRepoService) {
        $scope.updateOpenstackIP = function () {
            var openstack_ip = $scope.openstack_ip;

            //var keystone_version = $scope.dc_default.keystone_api.split(":")[1]
            var keystone_port = $scope.dc_default.keystone_api.split(":")[1].split("/")[0]
            var heat_port = $scope.dc_default.heat_api.split(":")[1].split("/")[0]
            var compute_port = $scope.dc_default.compute_api.split(":")[1].split("/")[0]
            var neutron_port = $scope.dc_default.neutron_api.split(":")[1].split("/")[0]
            $scope.dc_default = {
                msg: $scope.dc_default.msg,
                id: $scope.dc_default.id,
                adminName: $scope.dc_default.adminName,
                tenantName: $scope.dc_default.tenantName,
                adminPass: $scope.dc_default.adminPass,
                isAdmin: $scope.dc_default.isAdmin,
                openstack_ip: openstack_ip,
                keystone_api: openstack_ip + ":" + keystone_port + "/" + $scope.keystone_version,
                heat_api: openstack_ip + ":" + heat_port + "/" + $scope.heat_version,
                compute_api: openstack_ip + ":" + compute_port + "/" + $scope.compute_version,
                neutron_api: openstack_ip + ":" + neutron_port + "/" + $scope.neutron_version,
                dns: $scope.dc_default.dns,
                netfloc_ip : $scope.netfloc_ip,
                netfloc_user:$scope.netfloc_user,
                netfloc_pass: $scope.netfloc_pass,
                wicm_ip: $scope.wicm_ip
            }
        };
    });
