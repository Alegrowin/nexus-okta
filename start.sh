#!/bin/bash

/bin/echo "okta.org.url=${OKTA_URL}" >> /opt/sonatype/nexus/etc/nexus-okta-auth.properties
cat /opt/sonatype/nexus/etc/nexus-okta-auth.properties
sh -c /opt/sonatype/start-nexus-repository-manager.sh