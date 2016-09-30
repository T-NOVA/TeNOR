config = YAML.load_file("config/config.yml")
#quiet false
port config['port']
environment config['environment']
daemonize config['daemonize']
pidfile 'puma.pid'
state_path 'puma.state'
