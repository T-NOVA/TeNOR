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


# clears the bin/workspace directory from old json, dat and out files
if ls workspace/*.json 1> /dev/null 2>&1; then
    rm workspace/*.json
    echo "workspace/*.json deleted"
fi

if ls workspace/*.dat 1> /dev/null 2>&1; then
    rm workspace/*.dat
    echo "workspace/*.dat deleted"
fi

if ls workspace/*.out 1> /dev/null 2>&1; then
    rm workspace/*.out
    echo "workspace/*.out deleted"
fi
