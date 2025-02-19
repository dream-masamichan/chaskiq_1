# 🌟 ビルド用ステージ
ARG RUBY_VERSION  # ✅ `FROM` の前に定義
FROM ruby:${RUBY_VERSION}-slim-bullseye AS builder

ARG BUNDLER_VERSION
WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler:$BUNDLER_VERSION && \
    bundle install --deployment --without development test

# Node.js & Yarn のインストール
RUN gem update --system && \
    gem install bundler -v 2.3.26 && \
    bundle install --deployment --without development test

# 🌟 本番用ステージ
ARG RUBY_VERSION  # ✅ 本番用ステージでも `ARG` を定義
FROM ruby:${RUBY_VERSION}-slim-bullseye

ARG APP_ENV
ENV RAILS_ENV=${APP_ENV} \
    LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_APP_CONFIG=.bundle \
    PATH="/app/bin:$PATH"

WORKDIR /app

# 必要なパッケージをインストール
RUN apt-get update && apt-get install -y curl build-essential libpq-dev nodejs yarn && rm -rf /var/lib/apt/lists/*

# `vendor/bundle` と `node_modules` をコピー
COPY --from=builder /usr/src/app/vendor/bundle /app/vendor/bundle
COPY --from=builder /usr/src/app/node_modules /app/node_modules

# アプリのソースコードをコピー
COPY . ./

# `entrypoint.sh` を追加
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# ユーザー変更（root 回避）
RUN adduser --disabled-password --gecos "" appuser
RUN chown -R appuser:appuser /app
USER appuser

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server"]
