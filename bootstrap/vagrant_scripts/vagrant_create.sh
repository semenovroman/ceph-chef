#!/bin/bash
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

# Exit immediately if anything goes wrong, instead of making things worse.
set -e

################################################################################
# Function to remove VirtualBox DHCP servers
# By default, checks for any DHCP server on networks without VM's & removes them
# (expecting if a remove fails the function should bail)
# If a network is provided, removes that network's DHCP server
# (or passes the vboxmanage error and return code up to the caller)
#
function remove_DHCPservers {
  local network_name=${1-}
  if [[ -z "$network_name" ]]; then
    # make a list of VM UUID's
    local vms=$(VBoxManage list vms|sed 's/^.*{\([0-9a-f-]*\)}/\1/')
    # make a list of networks (e.g. "vboxnet0 vboxnet1")
    local vm_networks=$(for vm in $vms; do \
      VBoxManage showvminfo --details --machinereadable $vm | \
      grep -i '^hostonlyadapter[2-9]=' | \
      sed -e 's/^.*=//' -e 's/"//g'; \
    done | sort -u)
    # will produce a regular expression string of networks which are in use by VMs
    # (e.g. ^vboxnet0$|^vboxnet1$)
    local existing_nets_reg_ex=$(sed -e 's/^/^/' -e 's/$/$/' -e 's/ /$|^/g' <<< "$vm_networks")

    VBoxManage list dhcpservers | grep -E "^NetworkName:\s+HostInterfaceNetworking" | awk '{print $2}' |
    while read -r network_name; do
      [[ -n $existing_nets_reg_ex ]] && ! egrep -q $existing_nets_reg_ex <<< $network_name && continue
      remove_DHCPservers $network_name
    done
  else
    VBoxManage dhcpserver remove --netname "$network_name" && local return=0 || local return=$?
    return $return
  fi
}

###################################################################
# Function to create all VMs using Vagrant
function create_vagrant_vms {
  cd $REPO_ROOT/bootstrap/vagrant_scripts && vagrant up
}

# only execute functions if being run and not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  remove_DHCPservers
  create_vagrant_vms
fi
