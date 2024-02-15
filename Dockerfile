FROM node:latest AS git
ENV USER=nodebb \
  UID=1001 \
  GID=1001

RUN groupadd --gid $GID $USER
RUN useradd --uid $UID --gid $GID --create-home --shell /bin/bash $USER

WORKDIR /node-bb/

RUN git clone --recurse-submodules -j8 --depth 1 https://github.com/NodeBB/NodeBB.git .
RUN find . -mindepth 1 -maxdepth 1 -name '.*' ! -name '.' ! -name '..' -exec bash -c 'echo "Deleting {}"; rm -rf {}' \;

RUN rm -rf /node-bb/install/docker/entrypoint.sh
RUN rm -rf /node-bb/docker-compose.yml
RUN rm -rf /node-bb/Dockerfile

RUN sed -i 's|"\*/jquery":|"jquery":|g' /node-bb/install/package.json

RUN chown -R $USER:$USER /node-bb/
RUN apt-get update
RUN apt-get -y --no-install-recommends install tini

# === 'git' stage complete! ===

FROM node:latest AS node_modules-touch

RUN corepack enable

ENV USER=nodebb \
  UID=1001 \
  GID=1001 \
  PNPM_HOME="/pnpm" \
  PATH="$PNPM_HOME:$PATH" \
  NODE_ENV=production \
  daemon=false \
  silent=false

RUN groupadd --gid $GID $USER
RUN useradd --uid $UID --gid $GID --create-home --shell /bin/bash $USER

COPY --from=git --chown=$USER:$USER /node-bb/install/package.json /usr/src/app/

WORKDIR /usr/src/app/

USER $USER

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
  npm install --omit=dev \
  && pnpm import \
  && pnpm install --prod --frozen-lockfile \
  && rm -rf package-lock.json

# === 'node_modules-touch' stage complete! ===

FROM node:lts-slim AS final

ENV USER=nodebb \
  UID=1001 \
  GID=1001 \
  PNPM_HOME="/pnpm" \
  PATH="$PNPM_HOME:$PATH" \
  NODE_ENV=production \
  daemon=false \
  silent=false

WORKDIR /usr/src/app/

RUN corepack enable \
  && groupadd --gid $GID $USER \
  && useradd --uid $UID --gid $GID --home-dir /usr/src/app/ --shell /bin/bash $USER \
  && mkdir -p /opt/config/database/mongo/data/ /opt/config/database/mongo/config/ \
  && mkdir -p /usr/src/app/build/ /usr/src/app/public/uploads/ \
  && chown -R $USER:$USER /usr/src/app/ /opt/config/

COPY --from=node_modules-touch --chown=$USER:$USER /usr/src/app/ /usr/src/app/
COPY --from=git --chown=$USER:$USER /node-bb/ /usr/src/app/
COPY --from=git --chown=$USER:$USER /node-bb/install/docker/setup.json /usr/src/app/setup.json
COPY --from=git --chown=$USER:$USER /usr/bin/tini /usr/bin/tini
COPY --chown=$USER:$USER docker-entrypoint.sh /usr/local/bin/

USER $USER

EXPOSE 4567
VOLUME ["/usr/src/app/","/usr/src/app/build","/usr/src/app/public/uploads", "/opt/config/"]
ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]
