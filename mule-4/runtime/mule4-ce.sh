# WIP
curl -0 https://repository-master.mulesoft.org/nexus/content/repositories/releases/org/mule/distributions/mule-standalone/${RUNTIME_VERSION}/mule-standalone-${RUNTIME_VERSION}.tar.gz | \
    tar -zx -C ./
buildah copy --chown mule:root $container "mule-standalone-${RUNTIME_VERSION}" /opt/mule
rm -rf "mule-standalone-${RUNTIME_VERSION}"
