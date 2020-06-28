#!/usr/bin/bash

source common-helpers.sh
cmn_init || exit 3

if [[ -z $4 ]] ; then
 cmn_die "Please provide a following paramaters: the name of the distro and the release version. eg. ./openjdk-from-scratch.sh centos 8 jre 11"
else
  # Vars
  DISTRO_NAME=$1
  DISTRO_RELEASE=$2
  JAVA_RUNTIME=$3
  JAVA_MAJOR_VER=$4

  JAVA_PACKAGE="java"

  if [[ $JAVA_MAJOR_VER == "8" ]]; then
    JAVA_PACKAGE="$JAVA_PACKAGE-1.8.0"
  else
    JAVA_PACKAGE="$JAVA_PACKAGE-$JAVA_MAJOR_VER"
  fi

  if [[ $JAVA_RUNTIME == "jdk" ]]; then
    JAVA_PACKAGE="$JAVA_PACKAGE-devel"
  else
    JAVA_PACKAGE="$JAVA_PACKAGE-headless"
  fi
fi

# ------------------------------------------------------------------------------

cmn_echo_info "---> Building openjdk-${DISTRO_NAME}-${JAVA_RUNTIME}:${JAVA_MAJOR_VER} OCI"

container=$(buildah from scratch)

cmn_echo_info "---> Installing latest OpenJDK ${JAVA_MAJOR_VER}"
cmn_buildah_install_packages_scratch $container "shadow-utils $JAVA_PACKAGE" $DISTRO_RELEASE
buildah config --env JAVA_HOME=/etc/alternatives/jre $container
# This will give 181 from java version "1.8.0_181"
JAVA_VER=$(buildah run --runtime /usr/bin/runc ${container} -- java -version 2>&1 | head -n 1 | cut -d\" -f 2 | cut -d\_ -f 2)

if [[ $JAVA_MAJOR_VER == "8" ]]; then
  JAVA_VER="8u$JAVA_VER"
fi

cmn_echo_info "---> Configuring image"
buildah config --author "Jose Montoya <jam01@protonmail.com>" $container
buildah config --label name=openjdk ${container}

cmn_echo_info "---> Commiting quay.io/jam01/openjdk-${DISTRO_NAME}-${JAVA_RUNTIME}:${JAVA_VER}"
buildah commit --rm $container quay.io/jam01/openjdk-${DISTRO_NAME}-${JAVA_RUNTIME}:${JAVA_VER}
buildah tag quay.io/jam01/openjdk-${DISTRO_NAME}-${JAVA_RUNTIME}:${JAVA_VER} quay.io/jam01/openjdk-${DISTRO_NAME}-${JAVA_RUNTIME}:${JAVA_MAJOR_VER}

if [[ $JAVA_MAJOR_VER == "11" ]]; then
  # Tag as latest
  buildah tag quay.io/jam01/openjdk-${DISTRO_NAME}-${JAVA_RUNTIME}:${JAVA_VER} quay.io/jam01/openjdk-${DISTRO_NAME}-${JAVA_RUNTIME}:latest
fi
