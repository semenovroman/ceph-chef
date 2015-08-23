#
# Author:: Chris Jones <cjones303@bloomberg.net>
# Cookbook Name:: ceph-chef
# Recipe:: ceph-mon
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

# This recipe sets up ceph monitor configuration information needed by the ceph cookbook recipes
node['ceph']['config']['fsid'] = ceph_keygen()
node['ceph']['config]'['global']['public network'] = default['ceph-chef']['storage-frontend']['cidr']
node['ceph']['config]'['global']['cluster network'] = default['ceph-chef']['storage-backend']['cidr']

# Change these later - just here for testing...
node['ceph']['config]'['global']['osd pool default pg num'] = 128
node['ceph']['config]'['global']['osd pool default pgp num'] = 128
node['ceph']['config]'['global']['osd pool default size'] = 2
node['ceph']['config]'['global']['osd pool default min size'] = 1
node['ceph']['config]'['global']['osd pool default crush rule'] = 0
node['ceph']['config]'['global']['mon pg warn max per osd']=0
node['ceph']['config]'['global']['mon osd full ratio']=.85
node['ceph']['config]'['global']['mon osd nearfull ratio']=.70
node['ceph']['config]'['global']['osd backfill full ratio']=.70
