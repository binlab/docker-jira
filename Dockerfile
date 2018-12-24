FROM openjdk:8u181-alpine

LABEL maintainer="Mark <mark.binlab@gmail.com>"

ARG JIRA_CORE_VERS=7.13.0
ARG PGSQL_JDBC_VERS=42.2.5
ARG MYSQL_JDBC_VERS=5.1.46

ARG JIRA_VAR=/var/atlassian/jira
ARG JIRA_OPT=/opt/atlassian/jira

ARG JIRA_CORE_URL=https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-core-${JIRA_CORE_VERS}.tar.gz
ARG PGSQL_JDBC_URL=https://jdbc.postgresql.org/download/postgresql-${PGSQL_JDBC_VERS}.jar
ARG MYSQL_JDBC_URL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_JDBC_VERS}.tar.gz

ARG USER=jira
ARG GROUP=jira
ARG UID=1024
ARG GID=1024

ENV LC_ALL=C \
    JIRA_HOME=$JIRA_VAR \
    JIRA_INSTALL=$JIRA_OPT

RUN addgroup -S -g ${GID} ${GROUP} \
    && adduser -S -D -H -s /bin/false -g "${USER} service" \
           -u ${UID} -G ${GROUP} ${USER} \
    && mkdir -p ${JIRA_VAR} \
           ${JIRA_VAR}/caches/index \
           ${JIRA_OPT}/conf/Catalina \
    && apk add --no-cache --virtual .build-deps \
           curl \
           tar \
    && apk add --no-cache \
           bash \
           fontconfig \
           ttf-dejavu \
    && curl -Ls "${JIRA_CORE_URL}" \
           | tar -xz --directory "${JIRA_OPT}" \
               --strip-components=1 --no-same-owner \
    && cd ${JIRA_OPT}/lib \
    && rm -f ${JIRA_OPT}/lib/postgresql-9.* \
    && curl -Os ${PGSQL_JDBC_URL} \
    && curl -Ls ${MYSQL_JDBC_URL} \
           | tar -xz --directory ${JIRA_OPT}/lib \
               --strip-components=1 --no-same-owner \
               mysql-connector-java-${MYSQL_JDBC_VERS}/mysql-connector-java-${MYSQL_JDBC_VERS}-bin.jar \
    && chmod -R 700 \
           ${JIRA_VAR} \
           ${JIRA_OPT}/conf \
           ${JIRA_OPT}/temp \
           ${JIRA_OPT}/logs \
           ${JIRA_OPT}/work \
    && chown -R ${USER}:${GROUP} \
           ${JIRA_VAR} \
           ${JIRA_OPT}/conf \
           ${JIRA_OPT}/temp \
           ${JIRA_OPT}/logs \
           ${JIRA_OPT}/work \
    && sed -i "s/java version/openjdk version/g" ${JIRA_OPT}/bin/check-java.sh \
    && sed -i 's/JVM_MINIMUM_MEMORY="\(.*\)"/JVM_MINIMUM_MEMORY="${JVM_MINIMUM_MEMORY:=\1}"/g' ${JIRA_OPT}/bin/setenv.sh \
    && sed -i 's/JVM_MAXIMUM_MEMORY="\(.*\)"/JVM_MAXIMUM_MEMORY="${JVM_MAXIMUM_MEMORY:=\1}"/g' ${JIRA_OPT}/bin/setenv.sh \
    && echo -e "\njira.home=${JIRA_VAR}" >> ${JIRA_OPT}/atlassian-jira/WEB-INF/classes/jira-application.properties \
    && touch -d "@0" ${JIRA_OPT}/conf/server.xml \
    && apk del .build-deps

USER ${USER}

EXPOSE 8080

VOLUME ${JIRA_OPT}/logs
VOLUME ${JIRA_OPT}/conf
VOLUME ${JIRA_VAR}

WORKDIR ${JIRA_OPT}

CMD ["./bin/catalina.sh", "run"]
