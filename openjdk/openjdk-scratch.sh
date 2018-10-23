#!/usr/bin/bash

source common-helpers.sh
cmn_init || exit 3

if [[ -z $2 ]] ; then
 cmn_die "Please provide a following paramaters: the name of the distro and the release version. eg. ./openjdk-scratch.sh centos 7"
else
  # Vars
  DISTRO_NAME=$1
  RELEASE_VER=$2
fi

# ------------------------------------------------------------------------------

cmn_echo_info "---> Building openjdk:8-jre-slim-${DISTRO_NAME} OCI image"
cmn_echo_info "---> Preparing host"
yum update -y

container=$(buildah from scratch)
mount=$(buildah mount $container)

cmn_echo_info "---> Installing latest headless OpenJDK 8"
cmn_buildah_install_packages_scratch $container "shadow-utils java-1.8.0-openjdk-headless" $RELEASE_VER
buildah config --env JAVA_HOME=/etc/alternatives/jre $container
# This will give 181 from java version "1.8.0_181"
JAVA_VER=$(buildah run ${container} -- java -version 2>&1 | head -n 1 | cut -d\" -f 2 | cut -d\_ -f 2)

cmn_echo_info "---> Configuring image"
buildah config --author "Jose Montoya <jam01@protonmail.com>" $container
buildah config --label name=openjdk ${container}

cmn_echo_info "---> Commiting quay.io/jam01/openjdk:8u${JAVA_VER}-jre-slim-${DISTRO_NAME}"
buildah commit --rm $container quay.io/jam01/openjdk:8u${JAVA_VER}-jre-slim-${DISTRO_NAME}
buildah tag quay.io/jam01/openjdk:8u${JAVA_VER}-jre-slim-${DISTRO_NAME} quay.io/jam01/openjdk:8-jre-slim-${DISTRO_NAME}
