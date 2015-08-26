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

clear

echo " ____            _            ____ _           __ "
echo "/ ___| ___ _ __ | |__        / ___| |__   ___ / _|"
echo "| |   / _ \ '_ \| '_ \ _____| |   | '_ \ / _ \ |_ "
echo "| |__|  __/ |_) | | | |_____| |___| | | |  __/  _|"
echo "\____ \___| .__/|_| |_|      \____|_| |_|\___|_|  "
echo "          |_|                                     "
echo
echo "Ceph-Chef Vagrant BootstrapV2 0.9.0"
echo "--------------------------------------------"
echo "Bootstrapping local Vagrant environment..."
echo

while getopts vs opt; do
  case $opt in
    # verbose
    v)
      set -x
      ;;
    s)
      BOOTSTRAP_SKIP_VMS=1
      ;;
  esac
done

# Source common bootstrap functions. This is the only place that uses a
# relative path; everything henceforth must use $REPO_ROOT.
source ../common_scripts/bootstrap_functions.sh
export REPO_ROOT=$REPO_ROOT

# Source the bootstrap configuration file if present.
BOOTSTRAP_CONFIG="$REPO_ROOT/bootstrap/config/bootstrap_config.sh"
if [[ -f $BOOTSTRAP_CONFIG ]]; then
  source $BOOTSTRAP_CONFIG
fi

# Set all configuration variables that are not defined.
# DO NOT EDIT HERE; create bootstrap_config.sh as shown above from the
# template and define variables there.
# CEPH_OS: rhel, centos, ubuntu
# CEPH_VMS: all, bootstrap, mon, mds, rgw, osd, fs
export CEPH_OS=${CEPH_OS:-centos}
# Change CEPH_VMS here if you want to (see above)
export CEPH_VMS=all
export CEPH_VM_DIR=${CEPH_VM_DIR:-$HOME/CEPH-VMs}
export BOOTSTRAP_SKIP_VMS=${BOOTSTRAP_SKIP_VMS:-0}
export BOOTSTRAP_DOMAIN=${BOOTSTRAP_DOMAIN:-ceph.example.com}
export BOOTSTRAP_CHEF_ENV=${BOOTSTRAP_CHEF_ENV:-Test-Laptop-Vagrant}
export BOOTSTRAP_CHEF_DO_CONVERGE=${BOOTSTRAP_CHEF_DO_CONVERGE:-1}
export BOOTSTRAP_HTTP_PROXY=${BOOTSTRAP_HTTP_PROXY:-}
export BOOTSTRAP_HTTPS_PROXY=${BOOTSTRAP_HTTPS_PROXY:-}
#export BOOTSTRAP_ADDITIONAL_CACERTS_DIR=${BOOTSTRAP_ADDITIONAL_CACERTS_DIR:-}
export BOOTSTRAP_CACHE_DIR=${BOOTSTRAP_CACHE_DIR:-$HOME/.ceph-cache}
export BOOTSTRAP_APT_MIRROR=${BOOTSTRAP_APT_MIRROR:-}
export BOOTSTRAP_VM_MEM=${BOOTSTRAP_VM_MEM:-2048}
export BOOTSTRAP_VM_CPUS=${BOOTSTRAP_VM_CPUS:-1}
export BOOTSTRAP_VM_DRIVE_SIZE=${BOOTSTRAP_VM_DRIVE_SIZE:-20480}
export CLUSTER_VM_MEM=${CLUSTER_VM_MEM:-2560}
export CLUSTER_VM_CPUS=${CLUSTER_VM_CPUS:-2}
export CLUSTER_VM_DRIVE_SIZE=${CLUSTER_VM_DRIVE_SIZE:-20480}

# Perform preflight checks to validate environment sanity as much as possible.
echo "Performing preflight environment validation..."
source $REPO_ROOT/bootstrap/common_scripts/bootstrap_validate_env.sh

# Test that Vagrant is really installed and of an appropriate version.
if [[ $BOOTSTRAP_SKIP_VMS != 1 ]]; then
  echo "Checking VirtualBox and Vagrant..."
  source $REPO_ROOT/bootstrap/vagrant_scripts/vagrant_test.sh
fi

# Configure and test any proxies configured.
if [[ ! -z $BOOTSTRAP_HTTP_PROXY ]] || [[ ! -z $BOOTSTRAP_HTTPS_PROXY ]] ; then
  echo "Testing configured proxies..."
  source $REPO_ROOT/bootstrap/common_scripts/bootstrap_proxy_setup.sh
fi

# Do prerequisite work prior to starting build, downloading files and
# creating local directories.
echo "Downloading necessary files to local cache..."
source $REPO_ROOT/bootstrap/common_scripts/bootstrap_prereqs.sh

# Terminate existing CEPH VMs.
#if [[ $BOOTSTRAP_SKIP_VMS != 1 ]]; then
#  echo "Shutting down and unregistering VMs from VirtualBox..."
#  $REPO_ROOT/bootstrap/vagrant_scripts/vagrant_clean.sh

  # Create VMs in Vagrant and start them.
echo "Starting local Vagrant cluster..."
$REPO_ROOT/bootstrap/vagrant_scripts/vagrant_create.sh
#fi

# Install and configure Chef on all Vagrant hosts.
echo "Installing and configuring Chef on all nodes..."
$REPO_ROOT/bootstrap/vagrant_scripts/vagrant_configure_chef.sh

# Dump out useful information for users.
$REPO_ROOT/bootstrap/vagrant_scripts/vagrant_print_useful_info.sh
