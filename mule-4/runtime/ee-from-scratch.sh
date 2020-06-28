#!/usr/bin/bash

source common-helpers.sh
source mule-4/common-helpers.sh
cmn_init || exit 3

if [[ -z $4 ]] ; then
 cmn_die "Please provide the following paramaters: the name of the distro, the release version, and Mule runtime version. eg. ./ee-from-scratch.sh centos 8 4.1.4 8"
else
  # Vars
  DISTRO_NAME=$1
  DISTRO_RELEASE=$2
  RUNTIME_VER=$3
  JAVA_MAJOR_VER=$4
fi

# ------------------------------------------------------------------------------

cmn_echo_info "---> Building mule-4-ee-${DISTRO_NAME}:${RUNTIME_VER}-java${JAVA_MAJOR_VER} OCI"
cmn_echo_info "---> Preparing host"
yum install unzip -y


cmn_echo_info "---> Using quay.io/jam01/openjdk-${DISTRO_NAME}-jre:${JAVA_MAJOR_VER} as base image"
container=$(buildah from "quay.io/jam01/openjdk-${DISTRO_NAME}-jre:${JAVA_MAJOR_VER}")

# Packages needed by the wrapper
cmn_buildah_install_packages_scratch $container "gettext procps" $DISTRO_RELEASE
cmn_mule_create_user $container


cmn_echo_info "---> Downloading and extracting mule runtime"
curl -OJ https://s3.amazonaws.com/new-mule-artifacts/mule-ee-distribution-standalone-${RUNTIME_VER}.zip \
  && unzip -uoq mule-ee-distribution-standalone-${RUNTIME_VER}.zip
buildah copy --chown mule:root $container "mule-enterprise-standalone-${RUNTIME_VER}" /opt/mule
rm mule-ee-distribution-standalone-${RUNTIME_VER}.zip
rm -rf "mule-enterprise-standalone-${RUNTIME_VER}"


cmn_echo_info "---> Configuring runtime"
# enable log4j2 JMX
buildah run --runtime /usr/bin/runc ${container} --user root $container bash -c "sed -i '/log4j2.disable.jmx=true/s/^/#/'"
# include additional wrapper.conf properties
buildah run --runtime /usr/bin/runc ${container} --user root $container bash -c "sed -i '/^#include.*\/wrapper-additional.conf/s/^#//'"
buildah copy $container "./mule-4/runtime/wrapper-additional-java${JAVA_MAJOR_VER}.conf" "opt/mule/conf/wrapper-additional.conf"
buildah config --env MULE_HOME=/opt/mule $container
cmn_mule_add_group_permissions $container

# Expose the necessary port ranges as required by the Mule Apps
# HTTP listener default ports, remote debugger, JMX, MMC agent, AMC agent
buildah config --port 8081-8082,5000,1098,7777,9997 $container


cmn_echo_info "---> Configuring image"
buildah config --user mule $container
buildah config --cmd "/opt/mule/bin/mule" $container
buildah config --author "Jose Montoya <jam01@protonmail.com>" $container
buildah config --label name=mule-4-ee ${container}
buildah config --label io.k8s.description="Runtime for Mule 4 EE applications" ${container}
buildah config --label io.k8s.display-name="Mule 4 Enterprise Edition" ${container}
buildah config --label io.openshift.tags="integration,runtime,mule" ${container}


cmn_echo_info "---> Commiting quay.io/jam01/mule-4-ee-${DISTRO_NAME}:${RUNTIME_VER}-java${JAVA_MAJOR_VER}"
buildah commit --rm $container "quay.io/jam01/mule-4-ee-${DISTRO_NAME}:${RUNTIME_VER}-java${JAVA_MAJOR_VER}"
buildah tag "quay.io/jam01/mule-4-ee-${DISTRO_NAME}:${RUNTIME_VER}-java${JAVA_MAJOR_VER}" "quay.io/jam01/mule-4-ee-${DISTRO_NAME}:latest-java${JAVA_MAJOR_VER}"

if [[ $JAVA_MAJOR_VER == "11" ]]; then
  # Tag as latest
  buildah tag "quay.io/jam01/mule-4-ee-${DISTRO_NAME}:${RUNTIME_VER}-java${JAVA_MAJOR_VER}" "quay.io/jam01/mule-4-ee-${DISTRO_NAME}:latest"
fi
