#!/usr/bin/bash

source common-helpers.sh
source mule-4/common-helpers.sh
cmn_init || exit 3

if [[ -z $1 ]] ; then
 cmn_die "Please provide the following paramaters: the name openjdk-jdk version. eg. ./from-scratch.sh 8"
else
  # Vars
  JAVA_MAJOR_VER=$1
fi

# ------------------------------------------------------------------------------

cmn_echo_info "---> Building s2i-mule-builder:latest OCI image"

cmn_echo_info "---> Using quay.io/jam01/openjdk-centos-jdk:${JAVA_MAJOR_VER} as base image"
container=$(buildah from "quay.io/jam01/openjdk-centos-jdk:${JAVA_MAJOR_VER}")

cmn_buildah_install_packages_scratch $container "maven tar unzip rsync git" 8
cmn_mule_create_user $container


cmn_echo_info "---> Setting up S2I"
buildah copy $container "./mule-4/builder/s2i" "/usr/local/s2i"
buildah run --runtime /usr/bin/runc --user root $container bash -c 'chmod 755 /usr/local/s2i/*'
buildah run --runtime /usr/bin/runc --user mule $container bash -c 'mkdir /tmp/output'
buildah run --runtime /usr/bin/runc --user root $container bash -c 'mkdir /opt/mule/.m2'
buildah copy $container "./mule-4/builder/settings.xml" "/opt/mule/.m2/settings.xml"
cmn_mule_add_group_permissions $container


cmn_echo_info "---> Configuring image"
# Must use numeric user with S2I images
# See: https://docs.okd.io/latest/creating_images/guidelines.html#openshift-specific-guidelines
buildah config --user 1000 $container
buildah config --author "Jose Montoya <jam01@protonmail.com>" $container
buildah config --label name=s2i-mule-builder $container
buildah config --label io.openshift.s2i.scripts-url="image:///usr/local/s2i" $container
buildah config --label io.k8s.description="Platform for building Mule applications" ${container}
buildah config --label io.k8s.display-name="Mule Source To Image Builder" ${container}
buildah config --label io.openshift.tags="builder,mule" ${container}


cmn_echo_info "---> Commiting quay.io/jam01/s2i-mule-builder:1.0-java${JAVA_MAJOR_VER}"
buildah commit --rm $container quay.io/jam01/s2i-mule-builder:1.0-java${JAVA_MAJOR_VER}
buildah tag "quay.io/jam01/s2i-mule-builder:1.0-java${JAVA_MAJOR_VER}" "quay.io/jam01/s2i-mule-builder:latest-java${JAVA_MAJOR_VER}"

if [[ $JAVA_MAJOR_VER == "11" ]]; then
  # Tag as latest
  buildah tag "quay.io/jam01/s2i-mule-builder:1.0-java${JAVA_MAJOR_VER}" "quay.io/jam01/s2i-mule-builder:latest"
fi
