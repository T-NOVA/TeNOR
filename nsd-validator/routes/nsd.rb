# @see OrchestratorNsdValidator
class OrchestratorNsdValidator < Sinatra::Application

	before do

		if request.path_info == '/gk_credentials'
			return
		end

		if settings.environment == 'development'
			return
		end

		authorized?
	end

	# @method post_nsds
	# @note You have to specify the correct Content-Type
	# @overload post '/nsds'
	# 	Post a NSD in JSON format
	# 	@param [JSON]
	# 	@example Header for JSON
	# 		Content-Type: application/json
	# @overload post '/nsds'
	# 	Post a NSD in XML format
	# 	@param [XML]
	# 	@example Header for XML
	# 		Content-Type: application/xml
	#
	# Post a NSD
	post '/nsds' do
		# Read body content-type
		content_type = request.content_type
		body = request.body.read
		logger.debug "Content-Type: #{content_type}"

		# Return if content-type is invalid
		return 415 unless ( (content_type == 'application/json') or (content_type == 'application/xml') )

		# If message in JSON format
		if content_type == 'application/json'
			# Check if message is a valid JSON
			nsd, errors = parse_json(body)
			return 400, errors if errors

			# Check if message is a valid NSD
			nsd, errors = validate_json_nsd(nsd)
			return 400, errors if errors
		end

		# Parse XML format
		if content_type == 'application/xml'
			# Check if message is a valid XML
			nsd, errors = parse_xml(request.body.read)
			return 400, errors.to_json if errors

			# Check if message is a valid NSD
			nsd, errors = validate_xml_nsd(nsd)
			return 400, errors if errors
		end

		return 200
	end

end
