# Copyright 2014-2016 Universita' degli studi di Milano
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# -----------------------------------------------------
#
# Authors:
#     Alessandro Petrini (alessandro.petrini@unimi.it)
#
# -----------------------------------------------------
#


# Helper class for converting bit and bytes units

class Sm_converters

    # Converts a bw_string form the format "10GBits" to an integer
    # Note that returned bw is expressed in MBits
    def bw_conversion(bw_string)
        bw_units = {
            "kbits" => 0.001,
            "mbits" => 1,
            "gbits" => 1000,
            "kbps"  => 0.001,
            "mbps"  => 1,
            "gbps"  => 1000,
        }
        bw_value = bw_string[/[0-9]+/]
        bw_unit  = bw_string[/\D+/]
        return bw_value.to_i * bw_units[bw_unit.downcase].to_i
    end

    # Converts a bw_string form the format "10GBits" to an integer
    # Note that returned bw is expressed in GBits
    def bw_conversiongb(bw_string)
        bw_units = {
            "kbits" => 0.000001,
            "mbits" => 0.001,
            "gbits" => 1,
            "kbps"  => 0.000001,
            "mbps"  => 0.001,
            "gbps"  => 1,
        }
        bw_value = bw_string[/[0-9]+/]
        bw_unit  = bw_string[/\D+/]
        return bw_value.to_i * bw_units[bw_unit.downcase].to_i
    end

    # Converts a ram_value to MBytes
    def ram_conversion(ram_string, ram_unit)
        ram_units = {
            "kb" => 1/1024,
            "mb" => 1,
            "gb" => 1024,
            "kbytes"  => 1/1024,
            "mbytes"  => 1,
            "gbytes"  => 1024,
        }
        return ram_string.to_i * ram_units[ram_unit.downcase].to_i
    end

    # Converts a ram_value to MBytes
    def hdd_conversion(hdd_string, hdd_unit)
        hdd_units = {
            "kb" => 1/(1024 * 1024),
            "mb" => 1/1024,
            "gb" => 1,
            "kbytes"  => 1/(1024 * 1024),
            "mbytes"  => 1/1024,
            "gbytes"  => 1,
        }
        return hdd_string.to_i * hdd_units[hdd_unit.downcase].to_i
    end

end
