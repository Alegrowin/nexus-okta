FROM sonatype/nexus3:3.19.0

USER root

ARG NEXUS_OKTA_AUTH_VERSION=0.0.3
ARG OKTA_URL
ENV OKTA_URL=${OKTA_URL}}

ADD https://github.com/ruhkopf/nexus-okta-auth-plugin/releases/download/${NEXUS_OKTA_AUTH_VERSION}/nexus-okta-auth-plugin-${NEXUS_OKTA_AUTH_VERSION}.jar /opt/sonatype/nexus/system/nexus-okta-auth-plugin.jar
RUN echo "reference\:file\:nexus-okta-auth-plugin.jar = 200" >> /opt/sonatype/nexus/etc/karaf/startup.properties
COPY ./start.sh /opt/sonatype/start.sh
RUN chown nexus:nexus -R /opt/sonatype/nexus

USER nexus

CMD ["sh", "-c", "/opt/sonatype/start.sh"]