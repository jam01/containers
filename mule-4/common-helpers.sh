#
# COMMON MULE FUNCTIONS --------------------------------------------------------
#

# cmn_mule_create_user container
#
# Adds user "mule" under group root to allow openshift use
# See: https://github.com/fabric8io-images/java/blob/master/images/fedora/openjdk8/jre/Dockerfile
#
# Example:
# cmn_mule_create_user working_container
#
function cmn_mule_create_user {
  local container=${1}

  cmn_echo_info "---> Creating mule user"
  buildah run --runtime /usr/bin/runc --user root $container bash -c 'groupadd -r mule -g 1000 \
    && useradd -u 1000 -r -g mule -m -d /opt/mule -s /sbin/nologin mule \
    && chmod 755 /opt/mule \
    && usermod -g root -G `id -g mule` mule'

  cmn_mule_add_group_permissions $container
}

# cmn_mule_add_group_permissions container
#
# Allows root group members to read, write and execute files
# See: https://docs.okd.io/latest/creating_images/guidelines.html#openshift-specific-guidelines
#
# Example:
# cmn_mule_add_group_permissions working_container
#
function cmn_mule_add_group_permissions {
  local container=${1}

  buildah run --runtime /usr/bin/runc --user root $container bash -c 'chmod -R "g+rwX" /opt/mule'
}
