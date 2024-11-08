FROM ubuntu:jammy

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
    wget \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \

&& locale-gen en_US.UTF-8 \

&& mkdir -p ${HOME}/git/cardano-node2 && cd ${HOME}/git/cardano-node2 \
&& wget --progress=dot:giga https://github.com/IntersectMBO/cardano-node/releases/download/9.2.1/cardano-node-9.2.1-linux.tar.gz \
&& tar zxvf cardano-node-9.2.1-linux.tar.gz ./bin/cardano-node ./bin/cardano-cli \
&& $(find ${HOME}/git/cardano-node2 -type f -name "cardano-cli") version \
&& $(find ${HOME}/git/cardano-node2 -type f -name "cardano-node") version \
&& cp $(find ${HOME}/git/cardano-node2 -type f -name "cardano-cli") /usr/local/bin/cardano-cli \
&& cardano-cli version \
&& rm -rf ${HOME}/git \
\
&& useradd -m -s /bin/bash cardano \
&& echo "cardano:airgap" | chpasswd \
&& gpasswd -a cardano sudo \
\
&& mkdir -p /home/cardano/cnode/ \
&& mkdir -p /home/cardano/cold-keys/ \
&& mkdir -p /home/cardano/bin/ \
&& mkdir -p /mnt/share \
&& touch /home/cardano/.sudo_as_admin_successful
EOF

COPY ./bin/lock-keys /home/cardano/bin/
COPY ./bin/unlock-keys /home/cardano/bin/
COPY ./bin/ctool.sh /home/cardano/bin/

RUN chmod -R 755 /home/cardano/bin/* \
 && chown -R cardano: /home/cardano/bin \
 && chown -R cardano: /home/cardano/cnode \
 && chown -R cardano: /home/cardano/cold-keys \
 && chown -R cardano: /home/cardano/bin/* \
 && chown -R cardano: /mnt/share/

USER cardano
WORKDIR /home/cardano/

RUN echo export TERM=xterm-256color >> /home/cardano/.bashrc \
 && echo export NODE_HOME=/home/cardano/cnode >> /home/cardano/.bashrc \
 && echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> /home/cardano/.bashrc \
 && echo export NODE_NETWORK="--mainnet" >> /home/cardano/.bashrc \
 && echo export CARDANO_NODE_NETWORK_ID=mainnet >> /home/cardano/.bashrc \
 && echo export LANG=ja_JP.UTF-8 >> /home/cardano/.bashrc \
 && echo export PATH=${PATH}:${HOME}/bin >> /home/cardano/.bashrc \
 && echo alias ctool="ctool.sh" >> ${HOME}/.bashrc

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN . /home/cardano/.bashrc


ENTRYPOINT ["tail", "-F", "/dev/null"]
