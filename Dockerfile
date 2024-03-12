FROM node:latest AS git

ENV PNPM_HOME="/pnpm" \
  PATH="$PNPM_HOME:$PATH" \
  USER=nodebb \
  UID=1001 \
  GID=1001 \
  TZ="Asia/Seoul"

WORKDIR /usr/src/app/

RUN groupadd --gid ${GID} ${USER} \
  && useradd --uid ${UID} --gid ${GID} --home-dir /usr/src/app/ --shell /bin/bash ${USER} \
  && chown -R ${USER}:${USER} /usr/src/app/

RUN apt-get update \
  && apt-get -y --no-install-recommends install tini

USER ${USER}

RUN git clone --recurse-submodules -j8 --depth 1 https://github.com/NodeBB/NodeBB.git .

RUN find . -mindepth 1 -maxdepth 1 -name '.*' ! -name '.' ! -name '..' -exec bash -c 'echo "Deleting {}"; rm -rf {}' \; \
  && rm -rf install/docker/entrypoint.sh \
  && rm -rf docker-compose.yml \
  && rm -rf Dockerfile \
  && sed -i 's|"\*/jquery":|"jquery":|g' install/package.json

FROM node:latest AS node_modules_touch

ENV PNPM_HOME="/pnpm" \
  PATH="$PNPM_HOME:$PATH" \
  USER=nodebb \
  UID=1001 \
  GID=1001 \
  TZ="Asia/Seoul"

WORKDIR /usr/src/app/

RUN corepack enable \
  && groupadd --gid ${GID} ${USER} \
  && useradd --uid ${UID} --gid ${GID} --home-dir /usr/src/app/ --shell /bin/bash ${USER} \
  && chown -R ${USER}:${USER} /usr/src/app/

COPY --from=git --chown=${USER}:${USER} /usr/src/app/install/package.json /usr/src/app/

USER ${USER}

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
  npm install --package-lock-only --omit=dev \
  && pnpm import \
  && pnpm install \
    @nodebb/nodebb-plugin-reactions \
    nodebb-plugin-adsense \
    nodebb-plugin-extended-markdown \
    nodebb-plugin-meilisearch \
    nodebb-plugin-question-and-answer \
    nodebb-plugin-sso-github \
  && pnpm install --prod --frozen-lockfile \
  && npm cache clean --force \
  && rm -rf /usr/src/app/node_modules/.ignored_*

FROM node:lts-slim AS final

ENV NODE_ENV=production \
  DAEMON=false \
  SILENT=false \
  PNPM_HOME="/pnpm" \
  PATH="$PNPM_HOME:$PATH" \
  USER=nodebb \
  UID=1001 \
  GID=1001 \
  TZ="Asia/Seoul"

WORKDIR /usr/src/app/

RUN corepack enable \
  && groupadd --gid ${GID} ${USER} \
  && useradd --uid ${UID} --gid ${GID} --home-dir /usr/src/app/ --shell /bin/bash ${USER} \
  && mkdir -p /opt/config/database/mongo/data/ /opt/config/database/mongo/config/ /usr/src/app/logs/ \
  && chown -R ${USER}:${USER} /usr/src/app/ /opt/config/

COPY --from=node_modules_touch --chown=${USER}:${USER} /usr/src/app/ /usr/src/app/
COPY --from=git --chown=${USER}:${USER} /usr/src/app/ /usr/src/app/
COPY --from=git --chown=${USER}:${USER} /usr/src/app/install/docker/setup.json /usr/src/app/setup.json
COPY --from=git --chown=${USER}:${USER} /usr/bin/tini /usr/bin/tini
COPY --chown=${USER}:${USER} docker-entrypoint.sh /usr/local/bin/

USER ${USER}

EXPOSE 4567

VOLUME ["/usr/src/app/node_modules", "/usr/src/app/build", "/usr/src/app/public/uploads", "/opt/config/"]

ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]
## ENTRYPOINT ["tini", "--"]
## CMD ["start.sh"]
