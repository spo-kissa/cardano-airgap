FROM ubuntu:jammy

RUN mv /usr/bin/sh /usr/bin/sh_tmp && ln -s /usr/bin/bash /usr/bin/sh
ENV DEBIAN_FRONTEND noninteractive
RUN <<EOF
apt-get update \
&& apt-get install -y gpg curl \
&& apt-get clean && mkdir -p /etc/apt/keyrings \
&& curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg \
&& echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list \
&& apt-get update \
&& apt-get install -y \
    bash \
    bc \
    gum \
    htop \
    jq \
    locales \
    locales-all \
    nano \
    sudo \
    tmux \
    vim \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
\
&& locale-gen en_US.UTF-8 \
\
&& mkdir -p /home/cardano/git/cardano-node2 && cd /home/cardano/git/cardano-node2 \
&& curl -SL https://github.com/IntersectMBO/cardano-node/releases/download/10.1.4/cardano-node-10.1.4-linux.tar.gz \
 | tar -zxC /home/cardano/git/cardano-node2 ./bin/cardano-cli \
&& mv $(find /home/cardano/git/cardano-node2 -type f -name "cardano-cli") /usr/local/bin/cardano-cli \
&& cardano-cli version \
&& rm -rf /home/cardano/git \
\
&& useradd -m -s /bin/bash cardano \
&& echo "cardano:airgap" | chpasswd \
&& gpasswd -a cardano sudo \
\
&& mkdir -p /home/cardano/cnode/ \
&& mkdir -p /home/cardano/cold-keys/ \
&& mkdir -p /home/cardano/bin/ \
&& mkdir -p /mnt/share \
&& touch /home/cardano/.sudo_as_admin_successful \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EOF

COPY ./bin/lock-keys /home/cardano/bin/
COPY ./bin/unlock-keys /home/cardano/bin/
COPY ./bin/ctool.sh /home/cardano/bin/

RUN chmod -R 755 /home/cardano/bin/* \
 && chown -R cardano: /home/cardano/ \
 && chown -R cardano: /mnt/share/

USER cardano
ENV HOME=/home/cardano
WORKDIR /home/cardano/
ENV TERM=xterm-256color

RUN touch /home/cardano/.bashrc \
 && echo export TERM=xterm-256color >> /home/cardano/.bashrc \
 && echo export NODE_HOME=/home/cardano/cnode >> /home/cardano/.bashrc \
 && echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> /home/cardano/.bashrc \
 && echo export NODE_NETWORK="--mainnet" >> /home/cardano/.bashrc \
 && echo export CARDANO_NODE_NETWORK_ID=mainnet >> /home/cardano/.bashrc \
 && echo export LANG=ja_JP.UTF-8 >> /home/cardano/.bashrc \
 && echo export PATH=${PATH}:/home/cardano/bin >> /home/cardano/.bashrc \
 && echo alias ctool="ctool.sh" >> /home/cardano/.bashrc

RUN . /home/cardano/.bashrc
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENTRYPOINT ["tail", "-F", "/dev/null"]
