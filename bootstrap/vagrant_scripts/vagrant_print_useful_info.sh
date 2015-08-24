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

FAILED_ENVVAR_CHECK=0
REQUIRED_VARS=( BOOTSTRAP_CHEF_ENV REPO_ROOT )
for ENVVAR in ${REQUIRED_VARS[@]}; do
  if [[ -z ${!ENVVAR} ]]; then
    echo "Environment variable $ENVVAR must be set!" >&2
    FAILED_ENVVAR_CHECK=1
  fi
done
if [[ $FAILED_ENVVAR_CHECK != 0 ]]; then exit 1; fi

cd $REPO_ROOT/bootstrap/vagrant_scripts

KNIFE=/opt/opscode/embedded/bin/knife
# Dump the data bag contents to a variable.
DATA_BAG=$(vagrant ssh ceph-admin-bootstrap -c "$KNIFE data bag show configs $BOOTSTRAP_CHEF_ENV -F yaml")
# Get the management VIP.
MANAGEMENT_VIP=$(vagrant ssh ceph-admin-bootstrap -c "$KNIFE environment show $BOOTSTRAP_CHEF_ENV -a override_attributes.ceph-chef.management.vip | tail -n +2 | awk '{ print \$2 }'")

# this is highly naive for obvious reasons (will break on multi-line keys, spaces)
# but is sufficient for the items to be extracted here
extract_value() {
  echo "$DATA_BAG" | grep "$1:" | awk '{ print $2 }' | tr -d '\r\n'
}

# Parse certain data bag variables into environment variables for pretty printing.
ROOT_PASSWORD=$(extract_value 'cobbler-root-password')

# Print everything out for the user.
echo "------------------------------------------------------------"
echo "Everything looks like it's been installed successfully!"
echo
echo "Here are a few additional passwords:"
echo "System root password: $ROOT_PASSWORD"
echo
echo "Thanks for using Ceph-Chef!"
