FROM ubuntu:jammy

ARG PASSWD=airgap
ARG HOST_PWD=share

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y \
    jq \
    bc \
    tmux \
    htop \
    curl \
    wget \
    libncursesw5 \
    bash \
    locales \
    locales-all \
    sudo \
    nano \
    vim

RUN locale-gen en_US.UTF-8

RUN apt-get clean -y

RUN mkdir -p $HOME/git/cardano-node2 && cd $HOME/git/cardano-node2 \
    && wget https://github.com/IntersectMBO/cardano-node/releases/download/9.1.1/cardano-node-9.1.1-linux.tar.gz \
    && tar zxvf cardano-node-9.1.1-linux.tar.gz ./bin/cardano-node ./bin/cardano-cli \
    && $(find $HOME/git/cardano-node2 -type f -name "cardano-cli") version \
    && $(find $HOME/git/cardano-node2 -type f -name "cardano-node") version \
    && cp $(find $HOME/git/cardano-node2 -type f -name "cardano-cli") /usr/local/bin/cardano-cli \
    && cardano-cli version \
    && rm -rf $HOME\git

RUN useradd -m -s /bin/bash cardano && \
    echo "cardano:${PASSWD}" | chpasswd
RUN gpasswd -a cardano sudo


RUN mkdir /home/cardano/cnode/
RUN mkdir /home/cardano/cold-keys/

RUN chown -R cardano: /home/cardano/cnode/ \
    && chown -R cardano: /home/cardano/cold-keys/

COPY ./bin/copy-keys /home/cardano/bin/
COPY ./bin/lock-keys /home/cardano/bin/
COPY ./bin/unlock-keys /home/cardano/bin/
COPY ./bin/sign /home/cardano/bin/
COPY ./bin/ctool.sh /home/cardano/bin/
RUN chown -R cardano: /home/cardano/bin \
    && chmod -R 755 /home/cardano/bin/*

RUN mkdir /mnt/share && chown -R cardano: /mnt/share/

USER cardano
WORKDIR /home/cardano/

RUN echo export NODE_HOME=/home/cardano/cnode >> /home/cardano/.bashrc && \
    echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> /home/cardano/.bashrc && \
    echo export NODE_NETWORK="--mainnet" >> /home/cardano/.bashrc && \
    echo export CARDANO_NODE_NETWORK_ID=mainnet >> /home/cardano/.bashrc && \
    echo export LANG=ja_JP.UTF-8 >> /home/cardano/.bashrc && \
    echo export PATH=$PATH:$HOME/bin >> /home/cardano/.bashrc && \
    echo export HOST_PWD="${HOST_PWD}" >> /home/cardano/.bashrc && \
    echo alias ctool="ctool.sh" >> $HOME/.bashrc


ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN . /home/cardano/.bashrc


ENTRYPOINT ["tail", "-F", "/dev/null"]
