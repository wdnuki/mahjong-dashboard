FROM node:20-bookworm

# OS packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget unzip xz-utils libglu1-mesa ca-certificates python3 \
    && rm -rf /var/lib/apt/lists/*

# Flutter (web のみ)
ARG FLUTTER_VERSION=3.29.2
RUN curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt

ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="${FLUTTER_ROOT}/bin:${PATH}"
ENV FLUTTER_SUPPRESS_ANALYTICS=true
ENV PUB_CACHE=/root/.pub-cache

# Firebase CLI
RUN npm install -g firebase-tools@15.8.0

RUN mkdir -p /root/.config/configstore && \
    printf '{"analytics":{"optOut":true}}' \
    > /root/.config/configstore/firebase-tools.json

WORKDIR /workspace
CMD ["bash"]
