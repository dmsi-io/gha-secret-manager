FROM google/cloud-sdk:alpine

RUN apk --update add \
    jq \
    sed

COPY secret_manager.sh /secret_manager.sh

ENTRYPOINT ["/secret_manager.sh"]