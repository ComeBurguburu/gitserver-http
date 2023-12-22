FROM nginx:1.25

ARG BUILDPATH=build/DockerImages/git-http

RUN apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
     git bash fcgiwrap spawn-fcgi 

RUN git config --system http.receivepack true        &&  \
  git config --system http.uploadpack true           &&  \
  git config --system pack.windowMemory 2047M        &&  \
  git config --system pack.packSizeLimit 2047M       &&  \
  git config --system pack.deltaCacheSize 2047M      && \
  git config --system core.packedGitLimit 512M       && \
  git config --system core.packedGitWindowSize 512M  && \
  git config --system http.postBuffer 1024M          &&  \
  git config --system http.maxRequestBuffer 1024M    &&  \
  git config --system core.compression 0             &&  \
  git config --system user.email "gitserver@git.com" &&  \
  git config --system user.name "Git Server"

RUN ulimit -c unlimited
RUN useradd -m --uid 1000 git && usermod -g git git && \
    mkdir -p /var/lib/nginx/{body,fastcgi} && \
    chown -R git:git /usr/bin/spawn-fcgi /usr/sbin/nginx /usr/sbin/fcgiwrap /etc/nginx /var/lib/nginx/ /var/cache/

USER git

COPY --chown=git:git $BUILDPATH/default_project /home/default_project/workspace
COPY --chmod=755 --chown=git:git $BUILDPATH/entrypoint.sh /usr/local/bin/entrypoint
COPY --chown=git:git $BUILDPATH/etc /etc
RUN rm -f /etc/nginx/sites-enabled/default && nginx -t
CMD [ "bash","/usr/local/bin/entrypoint","-start"]
