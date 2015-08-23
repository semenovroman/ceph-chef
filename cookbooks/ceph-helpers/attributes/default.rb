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

###########################################
#
#  General configuration for this cluster
#
###########################################
default['ceph-helpers']['country'] = "US"
default['ceph-helpers']['state'] = "NY"
default['ceph-helpers']['location'] = "New York"
default['ceph-helpers']['organization'] = "Bloomberg"

# ulimits for libvirt-bin
default['ceph-helpers']['libvirt-bin']['ulimit']['nofile'] = 4096
# Region name for this cluster
default['ceph-helpers']['region_name'] = node.chef_environment
# Domain name for this cluster (used in many configs)
default['ceph-helpers']['domain_name'] = "ceph.example.com"

###########################################
#
# Package versions
#
###########################################

case node['platform_family']
when 'debian'
    default['ceph-helpers']['os']['version'] = '14.04'
    default['ceph-helpers']['ceph']['version'] = '0.94.2-1trusty'
    default['ceph-helpers']['ceph']['version_number'] = '0.94.2'
    # Ceph.com version number '0.94.2-1trusty'
    # This will enable auto-upgrades on all nodes (not recommended for stability)
    default['ceph-helpers']['enabled']['apt_upgrade'] = false
    # This will enable running apt-get update at the start of every Chef run
    default['ceph-helpers']['enabled']['always_update_package_lists'] = true
    default['ceph-helpers']['repos']['hwraid'] = "http://hwraid.le-vert.net/ubuntu"
    default['ceph-helpers']['repos']['ceph'] = "http://ceph.com/debian-hammer"
    # Note - us.archive.ubuntu.com tends to rate-limit pretty hard.
    # If you are on East Coast US, we recommend Columbia University in env file:
    # "mirror" : {
    #  "ubuntu": "mirror.cc.columbia.edu/pub/linux/ubuntu/archive"
    # }
    # For a complete list of Ubuntu mirrors, please see:
    # https://launchpad.net/ubuntu/+archivemirrors
    default['ceph-helpers']['mirror']['ubuntu'] = "us.archive.ubuntu.com/ubuntu"
    default['ceph-helpers']['mirror']['ubuntu-dist'] = ['trusty']
    # if you do specify a mirror, you can adjust the file path that comes
    # after the hostname in the URL here
    default['ceph-helpers']['bootstrap']['mirror_path'] = "/ubuntu"
    #
    # worked example for the columbia mirror mentioned above which has a
    # non-standard path
    #default['ceph-helpers']['bootstrap']['mirror']      = "mirror.cc.columbia.edu"
    #default['ceph-helpers']['bootstrap']['mirror_path'] = "/pub/linux/ubuntu/archive"

when 'rhel'
    default['ceph-helpers']['os']['version'] = 'rhel7.1'  # centos-7.1 for CentOS
    # The default for Redhat. The default for CentOS is el7 and is overridden in the environment json file.
    default['ceph-helpers']['ceph']['version'] = '0.94.2-0.el7'
    default['ceph-helpers']['ceph']['version_number'] = '0.94.2'
    # Only for individual rpms... Default yum repo has latest 'ceph'
    default['ceph-helpers']['ceph']['repo']['os'] = "el7"  # el7 for CentOS or rhel7 for RHEL
    default['ceph-helpers']['repos']['ceph'] = "http://ceph.com/rpm-hammer"

end

###########################################
#
#  Flags to enable/disable ceph cluster features
#
###########################################
# This will enable iptables firewall on all nodes
default['ceph-helpers']['enabled']['host_firewall'] = true
# This will enable of encryption of the chef data bag
default['ceph-helpers']['enabled']['encrypt_data_bag'] = false
# This will enable the networking test scripts
default['ceph-helpers']['enabled']['network_tests'] = true

# This will enable using TPM-based hwrngd
default['ceph-helpers']['enabled']['tpm'] = false

# If radosgw_cache is enabled, default to 20MB max file size
default['ceph-helpers']['radosgw']['cache_max_file_size'] = 20000000

###########################################
#
#  Host-specific defaults for the cluster
#
###########################################
default['ceph-helpers']['ceph']['hdd_disks'] = ["sdb", "sdc"]
default['ceph-helpers']['ceph']['ssd_disks'] = ["sdd", "sde"]
default['ceph-helpers']['ceph']['enabled_pools'] = ["ssd", "hdd"]

# rhel 7+ uses consistent naming interface names by default.
# Since these are defaults, we can keep them eth1..3.
# The environment json MUST override these attributes appropriately.
default['ceph-helpers']['management']['interface'] = "eth1"
# storage-backend - cluster in ceph terms
default['ceph-helpers']['storage-backend']['interface'] = "eth2"
# storage-frontend - public in ceph terms (old floating)
default['ceph-helpers']['storage-frontend']['interface'] = "eth3"

###########################################
#
#  Ceph settings for the cluster
#
###########################################
default['ceph-helpers']['ceph']['encrypted'] = false

# To use apache instead of civetweb, make the following value anything but 'civetweb'
default['ceph-helpers']['ceph']['frontend'] = "civetweb"
default['ceph-helpers']['ceph']['chooseleaf'] = "rack"
default['ceph-helpers']['ceph']['pgp_auto_adjust'] = false
# Need to review...
default['ceph-helpers']['ceph']['pgs_per_node'] = 1024
# Journal size could be 10GB or higher in some cases
default['ceph-helpers']['ceph']['journal_size'] = 10000
# The 'portion' parameters should add up to ~100 across all pools
default['ceph-helpers']['ceph']['default']['replicas'] = 3
default['ceph-helpers']['ceph']['default']['type'] = 'hdd'
default['ceph-helpers']['ceph']['rgw']['replicas'] = 3
default['ceph-helpers']['ceph']['rgw']['portion'] = 100
default['ceph-helpers']['ceph']['rgw']['type'] = 'hdd'

# Ruleset for CRUSH map
default['ceph-helpers']['ceph']['ssd']['ruleset'] = 1
default['ceph-helpers']['ceph']['hdd']['ruleset'] = 2

# If you are about to make a big change to the ceph cluster
# setting to true will reduce the load form the resulting
# ceph rebalance and keep things operational.
# See wiki for further details.
default['ceph-helpers']['ceph']['rebalance'] = false

# Set the default niceness of Ceph OSD and monitor processes
# Only need to set these if you're running a converged cluster with OpenStack and Ceph on same hardware nodes
#default['ceph-helpers']['ceph']['osd_niceness'] = -10
#default['ceph-helpers']['ceph']['mon_niceness'] = -10

###########################################
#
#  Network settings for the cluster
#
###########################################
# NOTE: Important - The IPs below are defaults. Change the IPs in the environment file(s)!
default['ceph-helpers']['management']['vip'] = "10.17.1.15"
default['ceph-helpers']['management']['netmask'] = "255.255.255.0"
default['ceph-helpers']['management']['cidr'] = "10.17.1.0/24"
default['ceph-helpers']['management']['gateway'] = "10.17.1.1"
default['ceph-helpers']['management']['interface'] = nil

default['ceph-helpers']['metadata']['ip'] = "169.254.169.254"

default['ceph-helpers']['storage-backend']['netmask'] = "255.255.255.0"
default['ceph-helpers']['storage-backend']['cidr'] = "100.100.0.0/24"
default['ceph-helpers']['storage-backend']['gateway'] = "100.100.0.1"
default['ceph-helpers']['storage-backend']['interface'] = nil
# if 'interface' is a VLAN interface, specifying a parent allows MTUs
# to be set properly
default['ceph-helpers']['storage-backend']['interface-parent'] = nil

default['ceph-helpers']['storage-frontend']['netmask'] = "255.255.255.0"
default['ceph-helpers']['storage-frontend']['cidr'] = "192.168.43.0/24"
default['ceph-helpers']['storage-frontend']['gateway'] = "192.168.43.2"
default['ceph-helpers']['storage-frontend']['interface'] = nil
# if 'interface' is a VLAN interface, specifying a parent allows MTUs
# to be set properly
default['ceph-helpers']['storage-frontend']['interface-parent'] = nil

default['ceph-helpers']['fixed']['cidr'] = "1.127.0.0/16"
default['ceph-helpers']['fixed']['num_networks'] = "100"
default['ceph-helpers']['fixed']['network_size'] = "256"
default['ceph-helpers']['fixed']['dhcp_lease_time'] = "120"

default['ceph-helpers']['ntp_servers'] = ["pool.ntp.org"]
default['ceph-helpers']['dns_servers'] = ["8.8.8.8", "8.8.4.4"]

###########################################
#
# [Optional] If using apt-mirror to pull down repos
#
###########################################
default['ceph-helpers']['mirror']['ceph-dist'] = ['hammer']

###########################################
#
#  Defaults for rgw
#
###########################################
# General ports for both Apache and Civetweb (no ssl for civetweb at this time)
default['ceph-helpers']['ports']['radosgw'] = 80
default['ceph-helpers']['ports']['radosgw_https'] = 443
default['ceph-helpers']['ports']['civetweb']['radosgw'] = 80

###########################################
#
# CPU governor settings
#
###########################################
#
# Available options: conservative, ondemand, userspace, powersave, performance
# Review documentation at https://www.kernel.org/doc/Documentation/cpu-freq/governors.txt
default['ceph-helpers']['cpupower']['governor'] = "ondemand"
default['ceph-helpers']['cpupower']['ondemand_ignore_nice_load'] = nil
default['ceph-helpers']['cpupower']['ondemand_io_is_busy'] = nil
default['ceph-helpers']['cpupower']['ondemand_powersave_bias'] = nil
default['ceph-helpers']['cpupower']['ondemand_sampling_down_factor'] = nil
default['ceph-helpers']['cpupower']['ondemand_sampling_rate'] = nil
default['ceph-helpers']['cpupower']['ondemand_up_threshold'] = nil

###########################################
#
# defaults for the bootstrap settings
#
###########################################
#
# A value of nil means to let the Ubuntu installer work it out - it
# will try to find the nearest one. However the selected mirror is
# often slow.
default['ceph-helpers']['bootstrap']['mirror'] = nil
