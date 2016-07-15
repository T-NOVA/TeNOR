# @see OrchestratorMonitoring
class OrchestratorMonitoring < Sinatra::Application

	# Checks if a Port is open
	#
	# @param [ip] ip of service
	# @param [port] port of service
	# @return [Boolean] is open or not
	def is_port_open?(ip, port)
	  begin
		Timeout::timeout(1) do
      begin
          s = TCPSocket.new(ip, port)
		      s.close
          return true
		  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
		    return false
      end
	  end
	  rescue Timeout::Error
	  end
	  return false
  end

  def getServiceList
    puts settings.api_source
    begin
      response = RestClient.get settings.api_source
      return JSON.parse(response)
    rescue => e
      puts e
      if (defined?(e.response)).nil?
        return nil
      end
      return nil
      #return e.response.code, e.response.body
    end
  end

  def list_inactive_services
    services = getServiceList
    elements = []
    services.each do |service|
      stat = is_port_open?(service['host'], service['port'])
      if stat == false
        elements.push(service)
      end
    end
    return elements
  end

  def service_checker(on=false, off=false)
    puts "Service checker function"
    services = getServiceList
    if services == nil
      return
    end
    elements_on = []
    elements_off = []

    services.each do |service|
      name = service["name"]
      path = service["path"]
      ip = service["host"]
      port = service["port"]

      status = is_port_open?(ip, port)
      if status # true == is connected aka service is "up"
        puts "Service: #{name}, IP: #{ip}, Port: #{port}: " + "Connected".color(Colors::GREEN)
        elements_on.push(service)
        service_status_pusher(name, "up")
      else
        puts "Service: #{name}, IP: #{ip}, Port: #{port}: " + "Disconnected".color(Colors::RED)
        elements_off.push(service)
        service_status_pusher(name, "down")
      end
    end

    if on
      return elements_on
    elsif off
      return elements_off
    end

  end

  def service_status_pusher(service_name, service_status)
    params = service_status
    begin
      response = RestClient.put settings.api_source + "/#{service_name}/status", params, :content_type => :text
    rescue => e
      #puts "#{e.message}".color(Colors::RED)
      #return message, e.to_s + "\n"
      return "Error pushing"
    end
  end

end

