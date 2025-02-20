ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-slim-bullseye

ARG APP_ENV
ARG PG_MAJOR
ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG YARN_VERSION

# 必要なパッケージをインストール（Node.js & Yarn を含む）
RUN apt-get update && apt-get install -y curl gnupg2 && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo "deb https://deb.nodesource.com/node_16.x bullseye main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs && \
    npm install -g yarn@1.22.19

# 作業ディレクトリを設定
WORKDIR /app

# 先に `package.json` と `yarn.lock` をコピー（キャッシュ活用のため）
COPY package.json yarn.lock /app/

# Yarn のキャッシュをクリアしてから依存関係をインストール
RUN yarn cache clean && yarn install --frozen-lockfile

# 先に `Gemfile` と `Gemfile.lock` をコピー（キャッシュを活用）
COPY Gemfile Gemfile.lock /app/

# Bundler のインストール
RUN gem update --system && \
    gem install bundler -v ${BUNDLER_VERSION} && \
    bundle config set without 'development test' && \
    bundle install --jobs=4 --retry=3

# アプリケーションの全ファイルをコピー
COPY . /app/

# `entrypoint.sh` の権限を設定
RUN chmod +x /app/entrypoint.sh

# ユーザー変更（root 回避）
RUN adduser --disabled-password --gecos "" appuser
RUN chown -R appuser:appuser /app
USER appuser

# アプリの起動
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server"]
