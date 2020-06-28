# WIP

container=$(buildah from openjdk:8-jre-slim)

echo "---> Building mule4-ee:openjdk-debian OCI image"
echo "---> Preparing base image"
buildah run --user root $container bash -c 'apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y procps \
  && apt-get autoclean \
  && apt-get --purge -y autoremove \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*'
