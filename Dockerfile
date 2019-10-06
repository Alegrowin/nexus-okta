FROM maven:3-jdk-8-alpine AS build

WORKDIR /plugins
RUN mkdir conan helm
# for remote tar file
RUN curl -L https://codeload.github.com/sonatype-nexus-community/nexus-repository-conan/tar.gz/8bb634b819d5be010ff7ef5c70d57e0a05c9b6f4 | tar -xz -C conan --strip-components=1
RUN curl -L https://codeload.github.com/sonatype-nexus-community/nexus-repository-helm/tar.gz/86e3cb4e65afd0092db0a426561056fd9e90a3a0 | tar -xz -C helm --strip-components=1
RUN curl -L https://github.com/ruhkopf/nexus-okta-auth-plugin/releases/download/0.0.3/nexus-okta-auth-plugin-0.0.3.jar -o nexus-okta-auth-plugin.jar

ARG NEXUS_VERSION=3.18.1
ARG NEXUS_BUILD=01

WORKDIR /plugins/conan
RUN sed -i "s/3.15.1-01/${NEXUS_VERSION}-${NEXUS_BUILD}/g" pom.xml; \
    mvn clean package -PbuildKar;

WORKDIR /plugins/helm
RUN sed -i "s/3.18.0-01/${NEXUS_VERSION}-${NEXUS_BUILD}/g" pom.xml; \
    mvn clean package;

FROM sonatype/nexus3:3.18.1
ARG NEXUS_VERSION=3.18.1
ARG NEXUS_BUILD=01
ARG CONAN_VERSION=0.0.6
ARG HELM_VERSION=0.0.13
ARG COMP_VERSION=1.18
ARG TARGET_DIR=/opt/sonatype/nexus/system/org/sonatype/nexus/plugins/nexus-repository-helm/${HELM_VERSION}/
ARG DEPLOY_DIR=/opt/sonatype/nexus/deploy/
USER root
RUN mkdir -p ${TARGET_DIR}; \
    sed -i 's@nexus-repository-maven</feature>@nexus-repository-maven</feature>\n        <feature prerequisite="false" dependency="false">nexus-repository-helm</feature>@g' /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml; \
    sed -i 's@<feature name="nexus-repository-maven"@<feature name="nexus-repository-helm" description="org.sonatype.nexus.plugins:nexus-repository-helm" version="'"${HELM_VERSION}"'">\n        <details>org.sonatype.nexus.plugins:nexus-repository-helm</details>\n        <bundle>mvn:org.sonatype.nexus.plugins/nexus-repository-helm/'"${HELM_VERSION}"'</bundle>\n        <bundle>mvn:org.apache.commons/commons-compress/'"${COMP_VERSION}"'</bundle>\n   </feature>\n    <feature name="nexus-repository-maven"@g' /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml;
COPY --from=build /plugins/helm/target/nexus-repository-helm-${HELM_VERSION}.jar ${TARGET_DIR}
COPY --from=build /plugins/conan/target/nexus-repository-conan-${CONAN_VERSION}-bundle.kar ${DEPLOY_DIR}
COPY --from=build /plugins/nexus-okta-auth-plugin.jar /opt/sonatype/nexus/system/nexus-okta-auth-plugin.jar

RUN echo "reference\:file\:nexus-okta-auth-plugin.jar = 200" >> /opt/sonatype/nexus/etc/karaf/startup.properties && \
    touch /opt/sonatype/nexus/etc/nexus-okta-auth.properties && \
    chown nexus:nexus -R /opt/sonatype/nexus

COPY ./start.sh /opt/sonatype/start.sh
RUN chmod 755 /opt/sonatype/start.sh

USER nexus

CMD ["sh", "-c", "/opt/sonatype/start.sh"]