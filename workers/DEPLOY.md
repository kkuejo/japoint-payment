# JAPOINT API デプロイ手順 (Cloudflare Workers + D1)

## 前提条件

- Node.js 18以上
- Cloudflareアカウント (kkuejo@yahoo.co.jp)
- Wrangler CLIがインストールされていること

## 手順

### 1. Wranglerのインストールとログイン

```bash
# Wranglerをインストール
npm install -g wrangler

# Cloudflareにログイン (ブラウザが開きます)
wrangler login
```

### 2. D1データベースの作成

```bash
cd /home/kenichiuejo/src/JAPOINT/workers

# D1データベースを作成
wrangler d1 create japoint-payments
```

出力例:
```
✅ Successfully created DB 'japoint-payments' in region APAC
Created your new D1 database.

[[d1_databases]]
binding = "DB"
database_name = "japoint-payments"
database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### 3. wrangler.tomlの更新

上記の出力から `database_id` をコピーして `wrangler.toml` を更新:

```toml
[[d1_databases]]
binding = "DB"
database_name = "japoint-payments"
database_id = "ここに実際のIDを貼り付け"
```

### 4. データベーススキーマの適用

```bash
# 本番環境にスキーマを適用
wrangler d1 execute japoint-payments --file=./schema.sql

# (オプション) ローカル開発用
wrangler d1 execute japoint-payments --local --file=./schema.sql
```

### 5. Workers のデプロイ

```bash
# 依存関係のインストール
npm install

# デプロイ
wrangler deploy
```

デプロイ後のURL例: `https://japoint-api.kkuejo.workers.dev`

### 6. フロントエンドの更新

`index.html` と `dashboard.html` の `API_URL` が正しいことを確認:

```javascript
const API_URL = 'https://japoint-api.kkuejo.workers.dev';
```

### 7. CORS設定の確認

`wrangler.toml` の `ALLOWED_ORIGINS` にフロントエンドのURLを追加:

```toml
[vars]
ALLOWED_ORIGINS = "https://kkuejo.github.io,https://japoint.pages.dev,http://localhost:8000"
```

## Cloudflare Pages へのフロントエンドデプロイ (オプション)

GitHub Pages の代わりに Cloudflare Pages を使う場合:

### 1. Cloudflare Dashboard でプロジェクト作成

1. https://dash.cloudflare.com にログイン
2. Pages → Create a project
3. GitHubと連携 → japoint-payment リポジトリを選択
4. ビルド設定:
   - Build command: (空のまま)
   - Build output directory: `/`
5. デプロイ

### 2. カスタムドメイン設定 (オプション)

Pages の設定から Custom domains を追加

## API エンドポイント

| メソッド | パス | 説明 |
|---------|------|------|
| GET | /api/health | ヘルスチェック |
| POST | /api/payments | 決済を記録 |
| GET | /api/payments | 決済履歴を取得 |
| GET | /api/payments/summary | 集計サマリーを取得 |
| GET | /api/payments/daily | 日別サマリーを取得 |

## トラブルシューティング

### CORS エラー

`wrangler.toml` の `ALLOWED_ORIGINS` にフロントエンドのオリジンを追加してから再デプロイ

### D1 エラー

```bash
# ローカルでテスト
wrangler dev

# ログを確認
wrangler tail
```

### データベースのリセット

```bash
# 本番データベースをリセット (注意: データが消えます)
wrangler d1 execute japoint-payments --command="DROP TABLE IF EXISTS payments; DROP TABLE IF EXISTS daily_summary;"
wrangler d1 execute japoint-payments --file=./schema.sql
```
