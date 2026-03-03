FROM node:20-bookworm

# ─────────────────────────────────────────────
# OS パッケージ
# ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget unzip xz-utils libglu1-mesa ca-certificates python3 \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────
# Flutter (web のみ precache して軽量化)
# ─────────────────────────────────────────────
ARG FLUTTER_VERSION=3.41.2
RUN curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt

ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="${FLUTTER_ROOT}/bin:${PATH}"
ENV FLUTTER_SUPPRESS_ANALYTICS=true
ENV PUB_CACHE=/root/.pub-cache

# web エンジンのみダウンロード（モバイル/デスクトップ toolchain を除外）
RUN flutter precache --web \
    --no-android --no-ios --no-linux --no-macos --no-windows

# ─────────────────────────────────────────────
# Firebase CLI / clasp (バージョン固定)
# ─────────────────────────────────────────────
RUN npm install -g firebase-tools@15.8.0 @google/clasp@3.2.0

# Firebase analytics 無効化（対話プロンプトをブロックしないよう）
RUN mkdir -p /root/.config/configstore && \
    printf '{"analytics":{"optOut":true}}' \
    > /root/.config/configstore/firebase-tools.json

# ─────────────────────────────────────────────
# 依存キャッシュレイヤー
# package.json / pubspec.yaml が変わらない限り再利用される
# ─────────────────────────────────────────────
WORKDIR /workspace/mahjong-dashboard

COPY gas_api/package.json gas_api/package-lock.json ./gas_api/
RUN cd gas_api && npm ci

COPY flutter_app/pubspec.yaml flutter_app/pubspec.lock ./flutter_app/
RUN cd flutter_app && flutter pub get

# ─────────────────────────────────────────────
# ソースコード
# ─────────────────────────────────────────────
COPY . .

CMD ["bash", "deploy.sh"]
