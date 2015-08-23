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

# Check for required environment variables and exit if not all are set.
FAILED_ENVVAR_CHECK=0
REQUIRED_VARS=( BOOTSTRAP_CACHE_DIR )
for ENVVAR in ${REQUIRED_VARS[@]}; do
  if [[ -z ${!ENVVAR} ]]; then
    echo "Environment variable $ENVVAR must be set!" >&2
    FAILED_ENVVAR_CHECK=1
  fi
done
if [[ $FAILED_ENVVAR_CHECK != 0 ]]; then exit 1; fi

# Create directory for download cache.
mkdir -p $BOOTSTRAP_CACHE_DIR

# download_file wraps the usual behavior of curling a remote URL to a local file
download_file() {
  FILE=$1
  URL=$2

  if [[ ! -f $BOOTSTRAP_CACHE_DIR/$FILE && ! -f $BOOTSTRAP_CACHE_DIR/${FILE}_downloaded ]]; then
    echo $FILE
    rm -f $BOOTSTRAP_CACHE_DIR/$FILE
    curl -L --progress-bar -o $BOOTSTRAP_CACHE_DIR/$FILE $URL
    touch $BOOTSTRAP_CACHE_DIR/${FILE}_downloaded
  fi
}

# This uses ROM-o-Matic to generate a custom PXE boot ROM.
# (doesn't use the function because of the unique curl command)
ROM=gpxe-1.0.1-80861004.rom
if [[ ! -f $BOOTSTRAP_CACHE_DIR/$ROM && ! -f $BOOTSTRAP_CACHE_DIR/${ROM}_downloaded ]]; then
  echo $ROM
  rm -f $BOOTSTRAP_CACHE_DIR/$ROM
  curl -L --progress-bar -o $BOOTSTRAP_CACHE_DIR/$ROM "http://rom-o-matic.net/gpxe/gpxe-1.0.1/contrib/rom-o-matic/build.php" -H "Origin: http://rom-o-matic.net" -H "Host: rom-o-matic.net" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Referer: http://rom-o-matic.net/gpxe/gpxe-1.0.1/contrib/rom-o-matic/build.php" -H "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3" --data "version=1.0.1&use_flags=1&ofmt=ROM+binary+%28flashable%29+image+%28.rom%29&nic=all-drivers&pci_vendor_code=8086&pci_device_code=1004&PRODUCT_NAME=&PRODUCT_SHORT_NAME=gPXE&CONSOLE_PCBIOS=on&BANNER_TIMEOUT=20&NET_PROTO_IPV4=on&COMCONSOLE=0x3F8&COMSPEED=115200&COMDATA=8&COMPARITY=0&COMSTOP=1&DOWNLOAD_PROTO_TFTP=on&DNS_RESOLVER=on&NMB_RESOLVER=off&IMAGE_ELF=on&IMAGE_NBI=on&IMAGE_MULTIBOOT=on&IMAGE_PXE=on&IMAGE_SCRIPT=on&IMAGE_BZIMAGE=on&IMAGE_COMBOOT=on&AUTOBOOT_CMD=on&NVO_CMD=on&CONFIG_CMD=on&IFMGMT_CMD=on&IWMGMT_CMD=on&ROUTE_CMD=on&IMAGE_CMD=on&DHCP_CMD=on&SANBOOT_CMD=on&LOGIN_CMD=on&embedded_script=&A=Get+Image"
  touch $BOOTSTRAP_CACHE_DIR/${ROM}_downloaded
fi

# Obtain an RHEL 7.1 image to be used for PXE booting.
# TODO: Come back and make it right :)
#download_file rhel-server-7.1-x86_64-dvd.iso http://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/installer-amd64/current/images/netboot/mini.iso

# Obtain a Vagrant RHEL box. # TODO: May have to build one for RHEL
#BOX=chef/centos-7.1.box
BOX=opscode_centos-7.1_chef-provisionerless.box
download_file $BOX http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/$BOX

# Obtain Chef client and server RPMs.
CHEF_CLIENT_RPM=chef-12.4.1-1.el7.x86_64.rpm
CHEF_SERVER_RPM=chef-server-core-12.1.0-1.el7.x86_64.rpm
download_file $CHEF_CLIENT_RPM https://opscode-omnibus-packages.s3.amazonaws.com/el/7/x86_64/$CHEF_CLIENT_RPM
download_file $CHEF_SERVER_RPM https://web-dl.packagecloud.io/chef/stable/packages/el/7/$CHEF_SERVER_RPM

# Pull needed cookbooks from the Chef Supermarket.
mkdir -p $BOOTSTRAP_CACHE_DIR/cookbooks
download_file cookbooks/ntp-1.8.6.tar.gz http://cookbooks.opscode.com/api/v1/cookbooks/ntp/versions/1.8.6/download
download_file cookbooks/yum-3.2.2.tar.gz http://cookbooks.opscode.com/api/v1/cookbooks/yum/versions/3.2.2/download

# Pull knife-acl gem.
download_file knife-acl-0.0.12.gem https://rubygems.global.ssl.fastly.net/gems/knife-acl-0.0.12.gem
