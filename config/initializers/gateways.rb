gateway_config = YAML::load_file(Rails.root.join('config', 'gateway.yml'))
gateway_names = gateway_config['gateways'].split(' ')
gateway_names_with_ip = {}
gateway_names.each { |name| gateway_names_with_ip[name] = gateway_config['gateway'][name] }

Rails.application.config.gateway_names = gateway_names
Rails.application.config.gateway_names_with_ip = gateway_names_with_ip
