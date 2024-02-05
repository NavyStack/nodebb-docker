FROM debian:bookworm-slim AS FINAL

ARG USER=mongodb \
    UID=1001 \
    GID=1001

ARG GOSU_VERSION=1.16 \
    JSYAML_VERSION=3.13.1

ARG MONGO_MAJOR=7.0 \
    MONGO_VERSION=7.0.5

ARG MONGO_PACKAGE=mongodb-org \
    MONGO_REPO=repo.mongodb.org

ARG MONGO_GPG_KEY=E58830201F7DD82CD808AA84160D26BB1785BA38

RUN set -eux \
    && groupadd --gid ${GID} --system ${USER} \
    && useradd --uid ${UID} --system --gid ${GID} --home-dir /data/db mongodb \
    && mkdir -p /data/db /data/configdb \
    && chown -R ${USER}:${USER} /data/db /data/configdb \
    \
    && apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            gnupg \
            jq \
            numactl \
            procps \
            wget \
        && rm -rf /var/lib/apt/lists/* \
    \
    && savedAptMark="$(apt-mark showmanual)" \
        && apt-get update \
            && apt-get install -y --no-install-recommends \
                wget \
        && rm -rf /var/lib/apt/lists/* \
    \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
        && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$dpkgArch" \
        && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$dpkgArch.asc" \
    \
    && export GNUPGHOME="$(mktemp -d)" \
        && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
        && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
            && gpgconf --kill all \
        && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    \
    && mkdir -p /opt/js-yaml/ \
        && wget -O /opt/js-yaml/js-yaml.js "https://github.com/nodeca/js-yaml/raw/${JSYAML_VERSION}/dist/js-yaml.js" \
        && wget -O /opt/js-yaml/package.json "https://github.com/nodeca/js-yaml/raw/${JSYAML_VERSION}/package.json" \
    && ln -s /opt/js-yaml/js-yaml.js /js-yaml.js \
    \
    && apt-mark auto '.*' > /dev/null \
        && apt-mark manual $savedAptMark > /dev/null \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    \
    && chmod +x /usr/local/bin/gosu \
        && gosu --version \
        && gosu nobody true \
    \
    && mkdir /docker-entrypoint-initdb.d \
    \
    && export GNUPGHOME="$(mktemp -d)" \
        && set -- ${MONGO_GPG_KEY} \
            && for key in "$@"; do gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; done \
                && mkdir -p /etc/apt/keyrings \
                    && gpg --batch --export "$@" > /etc/apt/keyrings/mongodb.gpg \
                        && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && echo "deb [ signed-by=/etc/apt/keyrings/mongodb.gpg ] http://${MONGO_REPO}/apt/ubuntu jammy/${MONGO_PACKAGE%-unstable}/${MONGO_MAJOR} multiverse" \
        | tee "/etc/apt/sources.list.d/${MONGO_PACKAGE%-unstable}.list" \
    \
    && export DEBIAN_FRONTEND=noninteractive \
    \
    && apt-get update \
        && apt-get install -y \
            ${MONGO_PACKAGE}=${MONGO_VERSION} \
            ${MONGO_PACKAGE}-server=${MONGO_VERSION} \
            ${MONGO_PACKAGE}-shell=${MONGO_VERSION} \
            ${MONGO_PACKAGE}-mongos=${MONGO_VERSION} \
            ${MONGO_PACKAGE}-tools=${MONGO_VERSION} \
            ${MONGO_PACKAGE}-database=${MONGO_VERSION} \
            ${MONGO_PACKAGE}-database-tools-extra=${MONGO_VERSION} \
            tini \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /var/lib/mongodb \
    \
    && mv /etc/mongod.conf /etc/mongod.conf.orig

VOLUME ["/data/db", "/data/configdb"]

ENV HOME /data/db

COPY --from=mongo:7 --chown=${USER}:${USER} /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
COPY --chown=${USER}:${USER} ./nodebb-mongo-init.js /docker-entrypoint-initdb.d/user-init.js

ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]

EXPOSE 27017
USER ${USER}
CMD ["mongod"]
