# ✅ 1️⃣ Ruby の公式イメージをベースに使用（軽量版）
ARG RUBY_VERSION=3.2.2
FROM ruby:${RUBY_VERSION}-slim

# ✅ 2️⃣ 必要な環境変数を設定
ENV LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_PATH=/usr/local/bundle \
    RAILS_ENV=development \
    NODE_ENV=development

# ✅ 3️⃣ 必要なライブラリをインストール（`build-essential` は gem のビルドに必要）
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    nodejs \
    yarn \
    && rm -rf /var/lib/apt/lists/*

# ✅ 4️⃣ 作業ディレクトリを `/app` に設定
WORKDIR /app

# ✅ 5️⃣ `Gemfile` だけをコピーし、`bundle install` を実行（キャッシュを活用）
COPY Gemfile Gemfile.lock /app/
RUN bundle install --jobs=4 --retry=3

# ✅ 6️⃣ 残りのファイルをコピー（変更時も `bundle install` を再実行しない）
COPY . /app

# ✅ 7️⃣ アセットのプリコンパイル（必要に応じて）
RUN bundle exec rails assets:precompile || true

# ✅ 8️⃣ コンテナを実行するユーザーを `appuser` に変更（セキュリティ対策）
RUN addgroup --system appgroup && adduser --system --group appuser
RUN chown -R appuser:appgroup /app
USER appuser

# ✅ 9️⃣ Rails サーバーを起動
# Dockerfile の最後に追加（または修正）
CMD ["sh", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]


