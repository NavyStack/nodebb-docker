FROM node:latest AS git
ARG USER=nodebb \
    UID=1001 \
    GID=1001

RUN groupadd --gid ${GID} ${USER}
RUN useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USER}

WORKDIR /node-bb/

RUN git clone --recurse-submodules -j8 --depth 1 https://github.com/NodeBB/NodeBB.git .
RUN find . -mindepth 1 -maxdepth 1 -name '.*' ! -name '.' ! -name '..' -exec bash -c 'echo "Deleting {}"; rm -rf {}' \;
RUN chown -R ${USER}:${USER} /node-bb/
RUN apt-get update
RUN apt-get -y --no-install-recommends install tini

# === 'git' stage complete! ===

FROM node:latest AS node_modules-touch
ARG USER=nodebb UID=1001 GID=1001

RUN groupadd --gid ${GID} ${USER}
RUN useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USER}

COPY --from=git --chown=${USER}:${USER} /node-bb/install/package.json /usr/src/build/

WORKDIR /usr/src/build/

USER ${USER}

RUN npm install --omit=dev

# === 'node_modules-touch' stage complete! ===

FROM node:lts-slim AS final
ARG USER=nodebb UID=1001 GID=1001
ENV NODE_ENV=production daemon=false silent=false

WORKDIR /usr/src/app/

RUN groupadd --gid ${GID} ${USER} \
    && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USER} \
    && mkdir -p /opt/config/database/mongo/data /opt/config/database/mongo/config \
    && chown -R ${USER}:${USER} /usr/src/app/ /opt/config/

COPY --from=node_modules-touch --chown=${USER}:${USER} /usr/src/build/ /usr/src/app/
COPY --from=git --chown=${USER}:${USER} /node-bb/ /usr/src/app/
COPY --from=git --chown=${USER}:${USER} /node-bb/install/docker/setup.json /usr/src/app/setup.json
COPY --from=git --chown=${USER}:${USER} /usr/bin/tini /usr/bin/tini

USER ${USER}

EXPOSE 4567
VOLUME ["/usr/src/app/node_modules", "/usr/src/app/build", "/usr/src/app/public/uploads", "/opt/config"]
ENTRYPOINT ["tini", "--", "install/docker/entrypoint.sh"]
