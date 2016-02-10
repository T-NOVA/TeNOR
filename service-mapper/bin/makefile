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
# This software uses jsoncons library by Daniel A. Parker under Boost Software License
# https://github.com/danielaparker/jsoncons
#
# -----------------------------------------------------

RM := rm -rf

# All of the sources participating in the build are defined here
O_SRCS :=
CPP_SRCS :=
C_UPPER_SRCS :=
C_SRCS :=
S_UPPER_SRCS :=
OBJ_SRCS :=
ASM_SRCS :=
CXX_SRCS :=
C++_SRCS :=
CC_SRCS :=
OBJS :=
C++_DEPS :=
C_DEPS :=
CC_DEPS :=
CPP_DEPS :=
EXECUTABLES :=
CXX_DEPS :=
C_UPPER_DEPS :=
# Every subdirectory with source files must be described here
SUBDIRS := \

# Add inputs and outputs from these tool invocations to the build variables
CPP_SRCS += \
./jsonConverter.cpp ./solver.cpp

OBJS += \
./jsonConverter.o ./solver.o

CPP_DEPS += \
./jsonConverter.d ./solver.d


# Each subdirectory must supply rules for building sources it contributes
#%.o: ./%.cpp
#	@echo 'Building file: $<'
#	@echo 'Invoking: GCC C++ Compiler'
#	g++ -I./include/ -O0 -g3 -Wall -c -fmessage-length=0 -std=c++11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
#	@echo 'Finished building: $<'
#	@echo ' '

USER_OBJS :=

LIBS := -lglpk

# Add inputs and outputs from these tool invocations to the build variables

# All Target
all: jsonConverter	solver

# Tool invocations
jsonConverter:
	@echo 'Building target: $@'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I./include/ -O0 -g3 -Wall -c -fmessage-length=0 -std=c++11 -MMD -MP -o jsonConverter.o jsonConverter.cpp
	@echo 'Invoking: GCC C++ Linker'
	g++  -o "jsonConverter" jsonConverter.o
	@echo 'Finished building target: $@'
	@echo ' '

solver:
	@echo 'Building target: $@'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I./include/ -O0 -g3 -Wall -c -fmessage-length=0 -std=c++11 -MMD -MP -o solver.o solver.cpp
	@echo 'Invoking: GCC C++ Linker'
	g++  -o "solver" solver.o $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C++_DEPS)$(C_DEPS)$(CC_DEPS)$(CPP_DEPS)$(EXECUTABLES)$(CXX_DEPS)$(C_UPPER_DEPS) jsonConverter solver
	-@echo ' '

.PHONY: all clean dependents
.SECONDARY:
