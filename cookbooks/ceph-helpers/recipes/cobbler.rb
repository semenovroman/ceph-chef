#
# Author:: Chris Jones <cjones303@bloomberg.net>
# Cookbook Name:: ceph-helpers
# Recipe:: cobbler
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

package "whois"

# This is to help as an example of setting variables needed for PXE booting using Cobbler
ruby_block "initialize-cobbler-config" do
    block do
        make_config('cobbler-web-user', "cobbler")
        make_config('cobbler-web-password', secure_password)
        make_config('cobbler-web-password-digest', %x[ printf "#{get_config('cobbler-web-user')}:Cobbler:#{get_config('cobbler-web-password')}" | md5sum | awk '{print $1}' ])
        make_config('cobbler-root-password', secure_password)
        make_config('cobbler-root-password-salted', %x[ printf "#{get_config('cobbler-root-password')}" | mkpasswd -s -m sha-512 ])
    end
end
