#!/usr/bin/bash

source common-helpers.sh
source mule4/common-helpers.sh
cmn_init || exit 3

if [[ -z $3 ]] ; then
 cmn_die "Please provide the following paramaters: the name of the distro, the release version, and Mule runtime version. eg. ./mule4-ee-scratch.sh centos 7 4.1.4"
else
  # Vars
  distro_name=$1
  release_ver=$2
  runtime_ver=$3
fi

# ------------------------------------------------------------------------------

cmn_echo_info "---> Building mule4-ee:${runtime_ver}-${distro_name}-openjdk OCI image"
cmn_echo_info "---> Preparing host"
yum update -y && yum install unzip -y


cmn_echo_info "---> Using quay.io/jam01/openjdk:8-jre-slim-${distro_name} as base image"
container=$(buildah from quay.io/jam01/openjdk:8-jre-slim-${distro_name})

# Packages needed by the wrapper
cmn_buildah_install_packages_scratch $container "gettext procps" $release_ver
cmn_mule_create_user $container


cmn_echo_info "---> Downloading and extracting mule runtime"
curl -OJ https://s3.amazonaws.com/new-mule-artifacts/mule-ee-distribution-standalone-${runtime_ver}.zip \
  && unzip -uoq mule-ee-distribution-standalone-${runtime_ver}.zip
buildah copy --chown mule:root $container "mule-enterprise-standalone-${runtime_ver}" /opt/mule
rm mule-ee-distribution-standalone-${runtime_ver}.zip
rm -rf "mule-enterprise-standalone-${runtime_ver}"


cmn_echo_info "---> Configuring runtime"
buildah copy $container "./mule4/runtime/${runtime_ver}-wrapper.conf" "opt/mule/conf/wrapper.conf"
buildah config --env MULE_HOME=/opt/mule $container
cmn_mule_add_group_permissions $container

# Expose the necessary port ranges as required by the Mule Apps
# HTTP listener default ports, remote debugger, JMX, MMC agent, AMC agent
buildah config --port 8081-8082,5000,1098,7777,9997 $container


cmn_echo_info "---> Configuring image"
buildah config --user mule $container
buildah config --cmd "/opt/mule/bin/mule" $container
buildah config --author "Jose Montoya <jam01@protonmail.com>" $container
buildah config --label name=mule4-ee ${container}
buildah config --label io.k8s.description="Platform for running Mule 4 EE applications" ${container}
buildah config --label io.k8s.display-name="Mule 4 Enterprise Edition" ${container}
buildah config --label io.openshift.tags="integration,runtime,mule:4,mule-ee:4" ${container}


cmn_echo_info "---> Commiting quay.io/jam01/mule4-ee:${runtime_ver}-${distro_name}-openjdk"
buildah commit $container quay.io/jam01/mule4-ee:${runtime_ver}-${distro_name}-openjdk


# ------------------------------------------------------------------------------

cmn_echo_info "---> Building jam01/mule4-ee:${runtime_ver}-${distro_name}-openjdk-jaeger OCI image"


# Add OpenTracing Agent
cmn_echo_info "---> Adding OpenTracing Agent"
container_ot_home=/opt/opentracing-agent
buildah run --user root $container mkdir -p ${container_ot_home}/lib
buildah copy $container "opentracing-mule-agent.jar" ${container_ot_home}
buildah copy $container "lib" ${container_ot_home}/lib
buildah copy $container "./mule4/runtime/${runtime_ver}-ot-wrapper.conf" "opt/mule/conf/wrapper.conf"
buildah config --env OT_HOME=${container_ot_home} $container


cmn_echo_info "---> Configuring image"
buildah config --author "Jose Montoya <jam01@protonmail.com>" $container
buildah config --label name=mule4-ee-jaeger ${container}
buildah config --label io.openshift.tags="jaeger" ${container}


cmn_echo_info "---> Commiting quay.io/jam01/mule4-ee:${runtime_ver}-${distro_name}-openjdk-jaeger"
buildah commit -rm $container quay.io/jam01/mule4-ee:${runtime_ver}-${distro_name}-openjdk-jaeger
