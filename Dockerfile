# 🌟 ビルド用ステージ
FROM ruby:$RUBY_VERSION-slim-bullseye AS builder

# 必要な引数を定義
ARG BUNDLER_VERSION
ARG APP_ENV

# 作業ディレクトリを作成
WORKDIR /usr/src/app

# 必要なファイルをコピー
COPY Gemfile Gemfile.lock ./

# Bundler のセットアップ
RUN gem install bundler:$BUNDLER_VERSION && \
    bundle install --deployment --without development test

# 🌟 本番用ステージ
FROM ruby:$RUBY_VERSION-slim-bullseye

# 必要な引数を定義
ARG APP_ENV
ARG NODE_MAJOR
ARG YARN_VERSION
ARG PG_MAJOR

# 環境変数を設定
ENV RAILS_ENV=${APP_ENV} \
    LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# 作業ディレクトリを作成
WORKDIR /usr/src/app

# 必要なパッケージをインストール
RUN apt-get update && \
    apt-get install -y curl build-essential libpq-dev nodejs yarn && \
    rm -rf /var/lib/apt/lists/*

# `vendor/bundle` をビルド済みのステージからコピー
COPY --from=builder /usr/src/app/vendor/bundle /usr/src/app/vendor/bundle

# アプリケーションのソースコードをコピー
COPY . ./

# `entrypoint.sh` を追加
COPY entrypoint.sh /usr/src/app/entrypoint.sh
RUN chmod +x /usr/src/app/entrypoint.sh

# 権限を変更
RUN chown -R 1000:1000 /usr/src/app

# 非 root ユーザーを使用
USER 1000

# エントリーポイントを設定
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]

# Rails サーバーを起動
CMD ["bundle", "exec", "rails", "server"]
