FactoryGirl.define do
  factory :vnfr do
    sequence(:vnfr) { |n| {id: 'test_' + n.to_s, name: 'test-name'} }
    sequence(:vnfr) { |n| {
        _id: "5718fe9fb18cfb55b9000000",
        audit_log: null,
        created_at: "2016-04-21T16:23:59.811+00:00",
        deployment_flavour: "gold",
        lifecycle_event_history: [
            "CREATE_IN_PROGRESS",
            "CREATE_COMPLETE"
        ],
        lifecycle_events_values: {},
        lifecycle_info: {
            authentication_username: "vagrant",
            driver: "ssh",
            authentication_type: "PubKeyAuthentication",
            authentication: "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEAqKzv1O+8SG53PJsMWHpAaBbbwQ5bEbHMplnOvnfWiL21cfU+\nEQdY2JgjsLMJyMnS2mMBmopJQ8y2c1KS2yz30oz/2ac/PcbiRmX4PV2qqUgDdVj1\n5w5YQreSBMNfi+hXs2uhs5dsDfG1mbedXhyT9QFlimeiZH+WwmX+91A9GQrCTrQU\nSp7FQsiXyDBNUYmVsYYdP19XcNNc1OoReY8oCBzrrBR+vOf7XA6dh86HlM/ZBuQf\nSUEn8SdYeQM0975aDIrjhW8m3Fd3ZE3ZZKuCl7rbMLY8RRB8pSAkpFrBtyeqtN0H\nRj7HpAd+BGjfgrL+ivXmG5AZ3fSehTFSKsGDDQIDAQABAoIBACgFkIpXr7cH7ubE\nazN7HlkUQ2QVQep643H9ER8EVDTxvmGhrO5hbeVGhAFjGck4if0jTLgcY7HgmtHW\nH949VzfwGKzOECVaUUoe273DwcCUw61ORFpkfvClmdHjgYIyyMxbl2yDWzIbzdkB\nRieUZE7X2/3xBQkPdPf/N3X65eRQ1FYRR6wOp2dAONzw0xpq2TYOKdVBqgZS3Sa6\npksSDycaLlSJA/NN2y/FiIU8kkoUShYflRrsyheipQ9D5KMEmQASxWkDQu3xW+Wl\n60aUwnOrEGoMNAXAHUshfpbrsu3A6d59/6rykhc37z9tVUdTnPbX5KPDkWbKqC7H\nDdMSMsECgYEA34kRR8+nBd+fBNHPGsn++S8eaeczX0kMqRiATWq0ZPspcIbA2ojS\n0X5txoEFBjcZ8C2Nq56MjZtqfZRZCLfm1e/Dk2LP0x8vRS9BQRKwL//hypYqEC5l\norokfy91Ow0kxnHxiYvJy2riinTcqSc4/8u2PuDVGW6JnLRxCIcW1kUCgYEAwSw0\n9jVjwQCWhkRJr/17vCLuCmkSMzmTFSu9SEsrVAmrYeE2qJPNRySjTfnDa/yA3OxG\nj620F5yMrD0ONCtoSqU6VQt23KiS0DPmWkeCuv6eOYMxXGy721idHshCtY9PlSZg\nC/QKa2KQnKV/88UfHUt/3hcAlpJzSdWBSku4iikCgYEAgv1LRw2EDokQIj7gYg5k\nf5kA9YYqMHgaFyzoYnVY6KPVkL8mW+k5wNGZem04iH/Zj0jib+Mk8gZUzOoVkmpR\ntqQds0yABHONu7kJQBy3ailEIvcEBx9pJ4Z0xKMGy2fUWQWESNnFkpI71m7Mr8Lw\nP9UcIpSVy6Vetpl2c0zWMRECgYAGBlbwhuHBlz8amO6jaoh9aal68aP7rQQFWQPi\nSVXknRiXSOrnfxSb72yYdf2+VHXAbi4VNRm00tEgXhcfUWtDSLv1AxKF90v86mF4\n11ogcuiEaq8TbuC9Cpp750sNVpbo0/WS6d2ZU82m1RKUi8VYqI4oYxdFmvO1jc8m\nfg4XYQKBgQCebRk5OiGmHTKUHHuBnFyA1ZJpVPGzBBmyQo83gRQ9+KvBOHQHYQcC\nv8JYWnuTwKCcIJhcqA8UbIGhRKHtBnqLr3Ipg97gKBElO3bTzUUut0QcMd14i6ab\n9oaS/tg7BhxKkQyuYwIpSeqFeZeecID4dfMCMHgaPaAsz+epjv1NIw==\n-----END RSA PRIVATE KEY-----",
            authentication_port: 22,
            flavor_id_ref: "flavor0",
            events: {
                start: {
                    command: "/home/vagrant/scripts/start",
                    template_file: "{\"controller\":\"get_attr[vdu0,PublicIp]\", \"vdu0\":\"get_attr[vdu1,PublicIp]\"}",
                    template_file_format: "JSON"
                },
                stop: {
                    command: "/home/vagrant/scripts/stop",
                    template_file: "{}",
                    template_file_format: "JSON"
                }
            },
            vnf_container: "/home/vagrant/container/"
        },
        notifications: ["http://127.0.0.1:4000/ns-instances/5718fe8eb18cfb68c5000000/instantiate"],
        nsr_instance: ["57160081e4b0118e43647291"],
        stack_url: "http://10.10.1.2:8004/v1/5ec795bba92e4eaaa9eabd0af44891e3/stacks/TEMP155ef1a57a58800e36071fcd2db835a3/d88aab2d-a318-4671-8595-0387c8873c6d",
        updated_at: "2016-04-21T16:25:12.380+00:00",
        vim_id: "1dc4dbf7-2fb3-4acb-96fe-330306f78422",
        vlr_instances: null,
        vms_id: {
            vdu0: "75f8a9d5-4c60-4e9d-b703-5d988d8ac21f"
        },
        vnf_addresses: {},
        vnf_status: "1",
        vnfd_reference: "1603"
    }
    }
  end
end



