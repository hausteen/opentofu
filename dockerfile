ARG NAME=alpine
ARG TAG=latest
FROM ${NAME}:${TAG}
RUN apk update && apk add sshpass openssh
ARG USERNAME=opentofu
RUN adduser -D -h /home/${USERNAME}/ -s /bin/sh ${USERNAME}
RUN wget https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh && \ 
    /bin/sh ./install-opentofu.sh --install-method apk && \ 
    rm install-opentofu.sh
WORKDIR /home/${USERNAME}
USER ${USERNAME}
COPY --chown=${USERNAME}:${USERNAME} --chmod=755 ./entrypoint.sh ./
CMD ["/bin/sh", "entrypoint.sh"]
