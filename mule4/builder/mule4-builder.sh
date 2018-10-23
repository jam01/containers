#!/usr/bin/bash

source common-helpers.sh
source mule4/common-helpers.sh
cmn_init || exit 3

# ------------------------------------------------------------------------------

cmn_echo_info "---> Building s2i-mule-builder:latest OCI image"
cmn_echo_info "---> Preparing host"
yum update -y


cmn_echo_info "---> Using quay.io/jam01/openjdk:8-jre-slim-fedora as base image"
container=$(buildah from quay.io/jam01/openjdk:8-jre-slim-fedora)

cmn_buildah_install_packages_scratch $container "maven tar unzip rsync git" 29
cmn_mule_create_user $container


cmn_echo_info "---> Setting up S2I"
buildah copy $container "./mule4/builder/s2i" "/usr/local/s2i"
buildah run --user root $container bash -c 'chmod 755 /usr/local/s2i/*'
buildah run --user mule $container bash -c 'mkdir /tmp/output'
buildah run --user root $container bash -c 'mkdir /opt/mule/.m2'
buildah copy $container "./mule4/builder/settings.xml" "/opt/mule/.m2/settings.xml"
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
buildah config --label io.openshift.tags="builder,mule,mule-ee,mule-ce" ${container}


cmn_echo_info "---> Commiting quay.io/jam01/s2i-mule-builder:latest"
buildah commit -rm $container quay.io/jam01/s2i-mule-builder:latest
