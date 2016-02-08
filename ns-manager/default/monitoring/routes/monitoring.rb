# @see OrchestratorMonitoring
class OrchestratorMonitoring < Sinatra::Application

	def initialize()
		Thread.new do
			threaded
			inspector #main_loop process for service monitoring (status)
		end
		Thread.new do
			threaded
			#health_inspector #main_loop process for service working tests (health)
		end

		#t1=Thread.new{inspector()}
		#t1.join

		super()
	end

	# return list of just active (current) services
	get "/active_services" do
		status 200
		active_services = service_checker(on=true, off=false)
		return active_services.to_json
	end

	# return list of stopped/unavailable services
	# create alarms?
	get "/inactive_services" do
		status 200
		inactive_services = service_checker(on=false, off=true)
		return inactive_services.to_json
	end

	def inspector

		interval = settings.stat_interval
		puts "Check stat_interval value: #{interval}"+' seconds'

		#main loop
		if interval != 0
			loop do
				puts Time.now
				service_checker(on=false, off=true)
				sleep(interval)
			end
		end
	end

	def threaded
		Thread.new do
			loop do
				Kernel.exit if gets =~ /exit/
			end
		end
	end

end