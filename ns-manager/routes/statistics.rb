#
# TeNOR - NS Manager
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
# @see Statistics
class Statistics < Sinatra::Application

  # @method get_statistics
  # @overload get "/statistics/"
  # Get statistics list
  # @param [string]
  get '/statistics' do
    return StatisticModel.all.to_json
  end

  # @method post_statistics
  # @overload post "/statistics"
  # Post a statistic value
  # @param [string] Metric name
  post "/statistics/:metric" do
    updateStatistics(params['metric'])
  end

  # @method get_performance_stats
  # @overload get "/performance-stats"
  # Get information about performance
  get "/performance-stats" do
    return PerformanceStatisticModel.all.to_json
  end

  # @method post_performance_stats
  # @overload get "/performance-stats"
  # Post performance values
  post "/performance-stats" do
    body, errors = parse_json(request.body.read)
    savePerformance(body)
  end

end
