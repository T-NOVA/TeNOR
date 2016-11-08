#
# TeNOR - NS Monitoring
#
# Copyright 2014-2016 i2CAT Foundation, Portugal Telecom Inovação
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @see NSMonitoring
module ExpressionEvaluatorHelper
    def self.calc_expression(formula, values)
        return values[0] if values.size == 1
        operations = formula.split('(')[0]

        response = 0
        case type1
        when 'MIN'
            response = find_min(values)
        when 'MAX'
            response = find_max(values)
        when 'AVG'
            response = find_avg(values)
        when 'SUM'
            response = find_sum(values)
        end
        response
    end

    def find_min(values)
        val = values[0]
        values.each do |v|
            val = v if val > v
        end
        val
    end

    def find_max(values)
        val = values[0]
        values.each do |v|
            val = v if val < v
        end
        val
    end

    def find_avg(values)
        val = 0
        values.each do |v|
            val += v
        end
        val / values.size
    end

    def find_sum(values)
        val = 0
        values.each do |v|
            val += v
        end
        val
    end

    def self.logger
        Logging.logger
    end

    # Global, memoized, lazy initialized instance of a logger
    def self.logger
        @logger ||= Logger.new(STDOUT)
    end
end
