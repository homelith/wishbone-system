#### Installing Software ####
FROM ubuntu:18.04 AS Base
ENV INTERNAL_USER=guser
ENV FILE_DIR=docker

# useful pkg for development
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential git locales make rsync screen sudo tmux tzdata usbutils vim wget x11-apps xorg xterm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# required pkg for running gowin ide
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libglib2.0-0 libfontconfig1 kmod && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# required pkg for simulation
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y iverilog gtkwave && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#### Global Settings ####
# set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# copy install scripts
RUN chmod go+rx /root
COPY ${FILE_DIR}/install.sh /root/install.sh
COPY ${FILE_DIR}/settings.sh /root/settings.sh
RUN chmod +x /root/install.sh

#### User Settings ####
# add non-privilege user
RUN useradd -ms /bin/bash ${INTERNAL_USER}
RUN echo "${INTERNAL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER ${INTERNAL_USER}
WORKDIR /home/${INTERNAL_USER}

# modify user .bashrc
RUN echo "source /root/settings.sh" >> /home/${INTERNAL_USER}/.bashrc

#### Finalize ####
USER root
COPY ${FILE_DIR}/entrypoint.sh /root/entrypoint.sh
ENTRYPOINT [ "sh", "/root/entrypoint.sh" ]
CMD ["/bin/sh"]
