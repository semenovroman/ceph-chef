#
# Author:: Chris Jones <cjones303@bloomberg.net>
# Cookbook Name:: ceph-chef
# Recipe:: default
#
# Copyright 2015, Bloomberg Finance L.P.
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

# PURPOSE:
# This recipe installs packages which are useful for debugging the stack
# and troubleshooting system issues. Packages should not be included here
# if the stack itself depends on them for its normal operation.

# Network troubleshooting tools
package "ethtool"
package "nmap"
package "iperf"
package "curl"

# I/O troubleshooting tools
package "fio"
package "bc"
package "iotop"

# System troubleshooting tools
package "htop"
package "sysstat"
