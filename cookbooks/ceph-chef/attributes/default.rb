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
default['ceph-chef']['country'] = "US"
default['ceph-chef']['state'] = "NY"
default['ceph-chef']['location'] = "New York"
default['ceph-chef']['organization'] = "Bloomberg"

# ulimits for libvirt-bin
default['ceph-chef']['libvirt-bin']['ulimit']['nofile'] = 4096
# Region name for this cluster
default['ceph-chef']['region_name'] = node.chef_environment
# Domain name for this cluster (used in many configs)
default['ceph-chef']['domain_name'] = "ceph.example.com"

###########################################
#
# Package versions
#
###########################################

case node['platform_family']
when 'debian'
    default['ceph-chef']['os']['version'] = '14.04'
    default['ceph-chef']['ceph']['version'] = '0.94.2-1trusty'
    default['ceph-chef']['ceph']['version_number'] = '0.94.2'
    # Ceph.com version number '0.94.2-1trusty'
    # This will enable auto-upgrades on all nodes (not recommended for stability)
    default['ceph-chef']['enabled']['apt_upgrade'] = false
    # This will enable running apt-get update at the start of every Chef run
    default['ceph-chef']['enabled']['always_update_package_lists'] = true
    default['ceph-chef']['repos']['hwraid'] = "http://hwraid.le-vert.net/ubuntu"
    default['ceph-chef']['repos']['ceph'] = "http://ceph.com/debian-hammer"
    # Note - us.archive.ubuntu.com tends to rate-limit pretty hard.
    # If you are on East Coast US, we recommend Columbia University in env file:
    # "mirror" : {
    #  "ubuntu": "mirror.cc.columbia.edu/pub/linux/ubuntu/archive"
    # }
    # For a complete list of Ubuntu mirrors, please see:
    # https://launchpad.net/ubuntu/+archivemirrors
    default['ceph-chef']['mirror']['ubuntu'] = "us.archive.ubuntu.com/ubuntu"
    default['ceph-chef']['mirror']['ubuntu-dist'] = ['trusty']
    # if you do specify a mirror, you can adjust the file path that comes
    # after the hostname in the URL here
    default['ceph-chef']['bootstrap']['mirror_path'] = "/ubuntu"
    #
    # worked example for the columbia mirror mentioned above which has a
    # non-standard path
    #default['ceph-chef']['bootstrap']['mirror']      = "mirror.cc.columbia.edu"
    #default['ceph-chef']['bootstrap']['mirror_path'] = "/pub/linux/ubuntu/archive"

when 'rhel'
    default['ceph-chef']['os']['version'] = 'rhel7.1'  # centos-7.1 for CentOS
    # The default for Redhat. The default for CentOS is el7 and is overridden in the environment json file.
    default['ceph-chef']['ceph']['version'] = '0.94.2-0.el7'
    default['ceph-chef']['ceph']['version_number'] = '0.94.2'
    # Only for individual rpms... Default yum repo has latest 'ceph'
    default['ceph-chef']['ceph']['repo']['os'] = "el7"  # el7 for CentOS or rhel7 for RHEL
    default['ceph-chef']['repos']['ceph'] = "http://ceph.com/rpm-hammer"

end

###########################################
#
#  Flags to enable/disable ceph cluster features
#
###########################################
# This will enable iptables firewall on all nodes
default['ceph-chef']['enabled']['host_firewall'] = true
# This will enable of encryption of the chef data bag
default['ceph-chef']['enabled']['encrypt_data_bag'] = false
# This will enable the networking test scripts
default['ceph-chef']['enabled']['network_tests'] = true

# This will enable using TPM-based hwrngd
default['ceph-chef']['enabled']['tpm'] = false

# If radosgw_cache is enabled, default to 20MB max file size
default['ceph-chef']['radosgw']['cache_max_file_size'] = 20000000

###########################################
#
#  Host-specific defaults for the cluster
#
###########################################
default['ceph-chef']['ceph']['osd_hdd_devices'] = [{"device": "sdb"},{"device": "sdc"}]
default['ceph-chef']['ceph']['osd_ssd_devices'] = [{"device": "sdd"}, {"device": "sde"}]
default['ceph-chef']['ceph']['enabled_pools'] = ["ssd", "hdd"]

# rhel 7+ uses consistent naming interface names by default.
# Since these are defaults, we can keep them eth1..3.
# The environment json MUST override these attributes appropriately.
default['ceph-chef']['management']['interface'] = "eth1"
# storage-backend - cluster in ceph terms
default['ceph-chef']['storage-backend']['interface'] = "eth2"
# storage-frontend - public in ceph terms (old floating)
default['ceph-chef']['storage-frontend']['interface'] = "eth3"

###########################################
#
#  Ceph settings for the cluster
#
###########################################
default['ceph-chef']['ceph']['encrypted'] = false

# To use apache instead of civetweb, make the following value anything but 'civetweb'
default['ceph-chef']['ceph']['frontend'] = "civetweb"
default['ceph-chef']['ceph']['chooseleaf'] = "rack"
default['ceph-chef']['ceph']['pgp_auto_adjust'] = false
# Need to review...
default['ceph-chef']['ceph']['pgs_per_node'] = 1024
# Journal size could be 10GB or higher in some cases
default['ceph-chef']['ceph']['journal_size'] = 10000
# The 'portion' parameters should add up to ~100 across all pools
default['ceph-chef']['ceph']['default']['replicas'] = 3
default['ceph-chef']['ceph']['default']['type'] = 'hdd'
default['ceph-chef']['ceph']['rgw']['replicas'] = 3
default['ceph-chef']['ceph']['rgw']['portion'] = 100
default['ceph-chef']['ceph']['rgw']['type'] = 'hdd'

# Ruleset for CRUSH map
default['ceph-chef']['ceph']['ssd']['ruleset'] = 1
default['ceph-chef']['ceph']['hdd']['ruleset'] = 2

# If you are about to make a big change to the ceph cluster
# setting to true will reduce the load form the resulting
# ceph rebalance and keep things operational.
# See wiki for further details.
default['ceph-chef']['ceph']['rebalance'] = false

# Set the default niceness of Ceph OSD and monitor processes
# Only need to set these if you're running a converged cluster with OpenStack and Ceph on same hardware nodes
#default['ceph-chef']['ceph']['osd_niceness'] = -10
#default['ceph-chef']['ceph']['mon_niceness'] = -10

###########################################
#
#  Network settings for the cluster
#
###########################################
# NOTE: Important - The IPs below are defaults. Change the IPs in the environment file(s)!
default['ceph-chef']['management']['vip'] = "10.17.1.15"
default['ceph-chef']['management']['netmask'] = "255.255.255.0"
default['ceph-chef']['management']['cidr'] = "10.17.1.0/24"
default['ceph-chef']['management']['gateway'] = "10.17.1.1"
default['ceph-chef']['management']['interface'] = nil

default['ceph-chef']['metadata']['ip'] = "169.254.169.254"

default['ceph-chef']['storage-backend']['netmask'] = "255.255.255.0"
default['ceph-chef']['storage-backend']['cidr'] = "100.100.0.0/24"
default['ceph-chef']['storage-backend']['gateway'] = "100.100.0.1"
default['ceph-chef']['storage-backend']['interface'] = nil
# if 'interface' is a VLAN interface, specifying a parent allows MTUs
# to be set properly
default['ceph-chef']['storage-backend']['interface-parent'] = nil

default['ceph-chef']['storage-frontend']['netmask'] = "255.255.255.0"
default['ceph-chef']['storage-frontend']['cidr'] = "192.168.43.0/24"
default['ceph-chef']['storage-frontend']['gateway'] = "192.168.43.2"
default['ceph-chef']['storage-frontend']['interface'] = nil
# if 'interface' is a VLAN interface, specifying a parent allows MTUs
# to be set properly
default['ceph-chef']['storage-frontend']['interface-parent'] = nil

default['ceph-chef']['fixed']['cidr'] = "1.127.0.0/16"
default['ceph-chef']['fixed']['num_networks'] = "100"
default['ceph-chef']['fixed']['network_size'] = "256"
default['ceph-chef']['fixed']['dhcp_lease_time'] = "120"

default['ceph-chef']['ntp_servers'] = ["pool.ntp.org"]
default['ceph-chef']['dns_servers'] = ["8.8.8.8", "8.8.4.4"]

###########################################
#
# [Optional] If using apt-mirror to pull down repos
#
###########################################
default['ceph-chef']['mirror']['ceph-dist'] = ['hammer']

###########################################
#
#  Defaults for rgw
#
###########################################
# General ports for both Apache and Civetweb (no ssl for civetweb at this time)
default['ceph-chef']['ports']['radosgw'] = 80
default['ceph-chef']['ports']['radosgw_https'] = 443
default['ceph-chef']['ports']['civetweb']['radosgw'] = 80

###########################################
#
# CPU governor settings
#
###########################################
#
# Available options: conservative, ondemand, userspace, powersave, performance
# Review documentation at https://www.kernel.org/doc/Documentation/cpu-freq/governors.txt
default['ceph-chef']['cpupower']['governor'] = "ondemand"
default['ceph-chef']['cpupower']['ondemand_ignore_nice_load'] = nil
default['ceph-chef']['cpupower']['ondemand_io_is_busy'] = nil
default['ceph-chef']['cpupower']['ondemand_powersave_bias'] = nil
default['ceph-chef']['cpupower']['ondemand_sampling_down_factor'] = nil
default['ceph-chef']['cpupower']['ondemand_sampling_rate'] = nil
default['ceph-chef']['cpupower']['ondemand_up_threshold'] = nil

###########################################
#
# defaults for the bootstrap settings
#
###########################################
#
# A value of nil means to let the Ubuntu installer work it out - it
# will try to find the nearest one. However the selected mirror is
# often slow.
default['ceph-chef']['bootstrap']['mirror'] = nil
