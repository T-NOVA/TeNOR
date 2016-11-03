class Sla < ActiveRecord::Base
    has_many :parameters
    #  has_many :breaches

    validates_presence_of :nsi_id

    def includes?(param_id)
        parameters.select { |parameter| parameter[:id] == param_id }
    end

    def process_reading(parameter_values, reading)
        # parameter = Parameter.where("sla_id = ? AND parameter_id = ?", self.id, parameter_values['id']).first
        parameter = Parameter.where('sla_id = ? AND name = ?', id, parameter_values['name']).first

        unless parameter.nil?
            if SlaHelper.check_breach_sla(parameter['threshold'], reading)
                @breach = process_breach(parameter, reading)
            end
        end
        @breach
        # TODO: the above is instant processing, must process along a time-interval
    end

    private

    def process_breach(parameter, reading)
        store_breach(parameter, reading)
        notify_ns_manager @breach
    end

    def store_breach(parameter, reading)
        @breach = Breach.create(nsi_id: nsi_id, external_parameter_id: parameter.id, value: reading)
    end

    def notify_ns_manager(breach)
        self
        puts 'SLA Breach!'
        puts breach.inspect
        puts inspect
        puts 'NSR:ID: ' + nsi_id

        request = {
            parameter_id: breach.external_parameter_id
        }

        puts 'Inform to NS Manager about this.'
        puts Sinatra::Application.settings.manager + '/ns-instances/scaling/' + nsi_id + '/auto_scale'
        # Thread.new {
        begin
            response = RestClient.post Sinatra::Application.settings.manager + '/ns-instances/scaling/' + nsi_id + '/auto_scale', request.to_json, content_type: :json, accept: :json
        rescue => e
            puts e
        end
        puts response
        # }
        # auto_scale_policy: [
        # {
        # criteria: [{"assurance_parameter_id": "assurance_parameter_id" }],
        # actions: [ {"type": "scaling_out"}]
        # }
        # ]
    end
end
