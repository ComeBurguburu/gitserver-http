FROM ubuntu:20.04

RUN apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
     git bash fcgiwrap spawn-fcgi nginx

RUN git config --system http.receivepack true             &&  \
  git config --system http.uploadpack true              &&  \
  git config --system user.email "gitserver@git.com"    &&  \
  git config --system user.name "Git Server"

ADD default_project /home/default_project/workspace

RUN rm -f /etc/nginx/sites-enabled/default
COPY etc /etc
COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

RUN useradd -m --uid 1000 hdf
RUN chown -R hdf:hdf  /usr/local/bin/entrypoint /home/default_project/workspace /usr/bin/spawn-fcgi /usr/sbin/nginx /usr/sbin/fcgiwrap /etc/nginx /var/lib/nginx /var/log/nginx
RUN mkdir /home/git && chown -R hdf:hdf /home/git 

USER hdf
RUN nginx -t
CMD [ "bash","/usr/local/bin/entrypoint","-start"]
