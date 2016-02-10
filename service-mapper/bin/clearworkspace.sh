#!/bin/bash
#
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


# clears the bin/workspace directory
if [ -f "workspace/mapperResponse.json" ]
then
    rm workspace/mapperResponse.json
    echo "workspace/mapperResponse.json deleted"
fi

if [ -f "workspace/NI.json" ]
then
    rm workspace/NI.json
    echo "workspace/NI.json deleted"
fi

if [ -f "workspace/NS.json" ]
then
    rm workspace/NS.json
    echo "workspace/NS.json deleted"
fi

if [ -f "workspace/NI_generated.dat" ]
then
    rm workspace/NI_generated.dat
    echo "workspace/NI_generated.dat deleted"
fi

if [ -f "workspace/NS_generated.dat" ]
then
    rm workspace/NS_generated.dat
    echo "workspace/NS_generated.dat deleted"
fi

if [ -f "workspace/pref_generated.dat" ]
then
    rm workspace/pref_generated.dat
    echo "workspace/pref_generated.dat deleted"
fi

if [ -f "workspace/print_mip.out" ]
then
    rm workspace/print_mip.out
    echo "workspace/print_mip.out deleted"
fi
