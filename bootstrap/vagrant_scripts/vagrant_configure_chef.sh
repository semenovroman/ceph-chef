#!/bin/bash
#
# Author: Chris Jones <cjones303@bloomberg.net>
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

# TODO: MUST have platform neutral code added!!!!!

mon_node_start=10
rgw_node_start=20
osd_node_start=30

# Exit immediately if anything goes wrong, instead of making things worse on fresh builds
if [[ $BOOTSTRAP_SKIP_VMS == 0 ]]; then
  set -e
fi

FAILED_ENVVAR_CHECK=0
REQUIRED_VARS=( BOOTSTRAP_CHEF_DO_CONVERGE BOOTSTRAP_CHEF_ENV BOOTSTRAP_DOMAIN REPO_ROOT )
for ENVVAR in ${REQUIRED_VARS[@]}; do
  if [[ -z ${!ENVVAR} ]]; then
    echo "Environment variable $ENVVAR must be set!" >&2
    FAILED_ENVVAR_CHECK=1
  fi
done
if [[ $FAILED_ENVVAR_CHECK != 0 ]]; then exit 1; fi

# This script does a lot of stuff:
# - installs Chef Server on the ceph-bootstrap node
# - installs Chef client on all nodes

# It would be more efficient as something executed in one shot on each node, but
# doing it this way makes it easy to orchestrate operations between nodes. It will be
# overhauled at some point to not be Vagrant-specific.

do_on_node() {
  echo
  echo "Issuing command: vagrant ssh $1 -c ${*}"
  echo "----------------------------------------------------------------------------------------"
  NODE=$1
  shift
  COMMAND="${*}"
  vagrant ssh $NODE -c "$COMMAND"
}

cd $REPO_ROOT/bootstrap/vagrant_scripts

# use Chef Server embedded knife instead of the one in /usr/bin
KNIFE=/opt/opscode/embedded/bin/knife

# install and configure Chef Server 12 and Chef 12 client on the ceph-bootstrap node
do_on_node ceph-bootstrap "sudo rpm -Uvh \$(find /ceph-files/ -name chef-server\*rpm -not -name \*downloaded | tail -1)"

do_on_node ceph-bootstrap "sudo sh -c \"echo nginx[\'non_ssl_port\'] = 4000 > /etc/opscode/chef-server.rb\""
do_on_node ceph-bootstrap "sudo chef-server-ctl reconfigure"
do_on_node ceph-bootstrap "sudo chef-server-ctl user-create admin admin admin admin@localhost.com welcome --filename /etc/opscode/admin.pem"
do_on_node ceph-bootstrap "sudo chef-server-ctl org-create ceph ceph --association admin --filename /etc/opscode/ceph-validator.pem"
do_on_node ceph-bootstrap "sudo chmod 0644 /etc/opscode/admin.pem /etc/opscode/ceph-validator.pem"

# May not have files so keep going if none are found
if [[ $BOOTSTRAP_SKIP_VMS == 0 ]]; then
  set +e
fi
# NOTE: May need to change chef-\ to chef_\ in Ubuntu
do_on_node ceph-bootstrap "sudo rpm -Uvh \$(find /ceph-files/ -name chef-\*rpm -not -name \*downloaded | tail -1)"
if [[ $BOOTSTRAP_SKIP_VMS == 0 ]]; then
  set -e
fi

# configure knife on the ceph-bootstrap node and perform a knife ceph-bootstrap to create the ceph-bootstrap node in Chef
do_on_node ceph-bootstrap "mkdir -p \$HOME/.chef && echo -e \"chef_server_url 'https://bootstrap.$BOOTSTRAP_DOMAIN/organizations/ceph'\\\nvalidation_client_name 'ceph-validator'\\\nvalidation_key '/etc/opscode/ceph-validator.pem'\\\nnode_name 'admin'\\\nclient_key '/etc/opscode/admin.pem'\\\nknife['editor'] = 'vim'\\\ncookbook_path [ \\\"#{ENV['HOME']}/ceph-chef/cookbooks\\\" ]\" > \$HOME/.chef/knife.rb"
do_on_node ceph-bootstrap "$KNIFE ssl fetch"
do_on_node ceph-bootstrap "$KNIFE ceph-bootstrap -x vagrant -P vagrant --sudo 10.0.101.3"

# Initialize VM lists
#TODO: Maybe add these as environment variables and set them in vagrant later
ceph_mon_vms="ceph-mon-vm1 ceph-mon-vm2 ceph-mon-vm3"
ceph_mds_vms=""
ceph_rgw_vms="ceph-rgw-vm1"
ceph_osd_vms="ceph-osd-vm1 ceph-osd-vm2 ceph-osd-vm3"

# install the knife-acl plugin into embedded knife
do_on_node ceph-bootstrap "sudo /opt/opscode/embedded/bin/gem install /ceph-files/knife-acl-0.0.12.gem"

# setup epel first
do_on_node ceph-bootstrap "sudo yum install -y epel-release"
for vm in $ceph_mon_vms $ceph_mds_vms $ceph_rgw_vms $ceph_osd_vms; do
  do_on_node $vm "sudo yum install -y epel-release"
done

# rsync the Chef repository into the non-root user (vagrant)'s home directory
do_on_node ceph-bootstrap "sudo yum update"
do_on_node ceph-bootstrap "sudo yum install -y rsync"
do_on_node ceph-bootstrap "rsync -a /ceph-host/* \$HOME/ceph-chef"

# add the dependency cookbooks from the file cache
do_on_node ceph-bootstrap "echo 'Checking on dependency for cookbooks...'"
do_on_node ceph-bootstrap "cp /ceph-files/cookbooks/*.tar.gz \$HOME/ceph-chef/cookbooks && cd \$HOME/ceph-chef/cookbooks && ls -1 *.tar.gz | xargs -I% tar xvzf %"

# build binaries before uploading the ceph-chef cookbook
# (this step will change later but using the existing build_bins script for now)
do_on_node ceph-bootstrap "sudo yum update"
# build bins step requires internet access even despite the local cache (thanks setuptools), so configure proxies just for
# this step if necessary ($HOME/proxy_config.sh is created by Vagrant during initial setup and will be empty if no proxies were configured)

# upload all cookbooks, roles and our chosen environment to the Chef server
# (cookbook upload uses the cookbook_path set when configuring knife on the ceph-bootstrap node)
do_on_node ceph-bootstrap "echo 'Starting knife to upload...'"
do_on_node ceph-bootstrap "$KNIFE cookbook upload chef-client ceph cron logrotate ntp yum"
do_on_node ceph-bootstrap "cd \$HOME/ceph-chef/roles && $KNIFE role from file *.json"
do_on_node ceph-bootstrap "cd \$HOME/ceph-chef/environments && $KNIFE environment from file $BOOTSTRAP_CHEF_ENV.json"

# install and ceph-bootstrap Chef on cluster nodes
i=1
for vm in $ceph_mon_vms; do
  do_on_node $vm "sudo rpm -Uvh \$(find /ceph-files/ -name chef-\*rpm -not -name \*downloaded | tail -1)"
  do_on_node ceph-bootstrap "$KNIFE ceph-bootstrap -x vagrant -P vagrant --sudo 10.0.101.$(($mon_node_start+i))"
  i=`expr $i + 1`
done

i=1
for vm in $ceph_mds_vms; do
  do_on_node $vm "sudo rpm -Uvh \$(find /ceph-files/ -name chef-\*rpm -not -name \*downloaded | tail -1)"
  do_on_node ceph-bootstrap "$KNIFE ceph-bootstrap -x vagrant -P vagrant --sudo 10.0.101.$(($mds_node_start+i))"
  i=`expr $i + 1`
done

i=1
for vm in $ceph_rgw_vms; do
  do_on_node $vm "sudo rpm -Uvh \$(find /ceph-files/ -name chef-\*rpm -not -name \*downloaded | tail -1)"
  do_on_node ceph-bootstrap "$KNIFE ceph-bootstrap -x vagrant -P vagrant --sudo 10.0.101.$(($rgw_node_start+i))"
  i=`expr $i + 1`
done

i=1
for vm in $ceph_osd_vms; do
  do_on_node $vm "sudo rpm -Uvh \$(find /ceph-files/ -name chef-\*rpm -not -name \*downloaded | tail -1)"
  do_on_node ceph-bootstrap "$KNIFE ceph-bootstrap -x vagrant -P vagrant --sudo 10.0.101.$(($osd_node_start+i))"
  i=`expr $i + 1`
done

# augment the previously configured nodes with our newly uploaded environments and roles
for vm in ceph-bootstrap $ceph_mon_vms $ceph_mds_vms $ceph_rgw_vms $ceph_osd_vms; do
  do_on_node ceph-bootstrap "$KNIFE node environment set $vm.$BOOTSTRAP_DOMAIN $BOOTSTRAP_CHEF_ENV"
done

do_on_node ceph-bootstrap "$KNIFE node run_list set ceph-bootstrap.$BOOTSTRAP_DOMAIN 'role[bootstrap]'"
# ceph-mons
for vm in $ceph_mon_vms; do
  do_on_node ceph-bootstrap "$KNIFE node run_list set $vm.$BOOTSTRAP_DOMAIN 'role[ceph-mon]'"
done
# ceph-mds
for vm in $ceph_mds_vms; do
  do_on_node ceph-bootstrap "$KNIFE node run_list set $vm.$BOOTSTRAP_DOMAIN 'role[ceph-mds]'"
done
# ceph-rgws
for vm in $ceph_rgw_vms; do
  do_on_node ceph-bootstrap "$KNIFE node run_list set $vm.$BOOTSTRAP_DOMAIN 'role[ceph-rgw]'"
done
# ceph-osds
for vm in $ceph_osd_vms; do
  do_on_node ceph-bootstrap "$KNIFE node run_list set $vm.$BOOTSTRAP_DOMAIN 'role[ceph-osd]'"
done

# generate actor map
do_on_node ceph-bootstrap "cd \$HOME && $KNIFE actor map"
# using the actor map, set ceph-bootstrap, ceph-*-vms (if any) as admins so that they can write into the data bag
do_on_node ceph-bootstrap "cd \$HOME && $KNIFE group add actor admins ceph-bootstrap.$BOOTSTRAP_DOMAIN"  # && $KNIFE group add actor admins cos-vm1.$BOOTSTRAP_DOMAIN"

for vm in $ceph_mon_vms $ceph_rgw_vms $ceph_osd_vms; do
  do_on_node ceph-bootstrap "cd \$HOME && $KNIFE group add actor admins $vm.$BOOTSTRAP_DOMAIN"
done

# run Chef on each node
for vm in ceph-bootstrap $ceph_mon_vms $ceph_rgw_vms $ceph_osd_vms; do
  do_on_node $vm "sudo chef-client"
done
