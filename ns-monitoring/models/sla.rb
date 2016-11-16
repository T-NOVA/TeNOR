class Sla < ActiveRecord::Base
    has_many :parameters
    has_many :breaches

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

                #check if the num of breaches inside the violation interval
                breaches = Breach.where(nsi_id: nsi_id, external_parameter_id: parameter.parameter_id)
                if breaches.size >= parameter.violations[0].breaches_count
                    initial_time = breaches[0].created_at
                    final_time = breaches[breaches.size - 1].created_at
                    if initial_time + parameter.violations[0].interval < final_time
                        notify_ns_manager @breach
                        breaches.each do |br|
                            br.destroy
                        end
                    else
                        breaches[0].destroy
                    end
                end
            end
        end
        @breach
    end

    private

    def process_breach(parameter, reading)
        store_breach(parameter, reading)
        #notify_ns_manager @breach
    end

    def store_breach(parameter, reading)
        @breach = Breach.create(nsi_id: nsi_id, external_parameter_id: parameter.parameter_id, value: reading)
    end

    def notify_ns_manager(breach)
        self

        request = {
            parameter_id: breach.external_parameter_id
        }

        begin
            response = RestClient.post Sinatra::Application.settings.manager + '/ns-instances/scaling/' + nsi_id + '/auto_scale', request.to_json, content_type: :json, accept: :json
        rescue => e
            puts e
        end
    end
end
