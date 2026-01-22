# JAPOINT 決済システム

SolidityとFoundryで構築された、ステーブルコイン決済とポイント還元システムです。顧客がJPYC（日本円ステーブルコイン）で支払うと、JAPT（JAPoint）トークンがポイントとして還元されます。

## ライブデモ

- **決済システム**: https://japoint-payment.pages.dev
- **API**: https://japoint-api.kkuejo.workers.dev

## システムアーキテクチャ

```
フロントエンド (Cloudflare Pages)     バックエンド (Cloudflare Workers)
┌─────────────────────────┐          ┌─────────────────────────┐
│  index.html (店舗用)    │          │  Workers API            │
│  mobile-payment.html    │◄────────►│  - POST /api/payments   │
│  dashboard.html         │          │  - GET /api/payments    │
│  add-japt.html          │          │  - GET /api/summary     │
└───────────┬─────────────┘          └───────────┬─────────────┘
            │                                    │
            ▼                                    ▼
┌─────────────────────────┐          ┌─────────────────────────┐
│  MetaMask Mobile        │          │  Cloudflare D1          │
│  (ユーザーウォレット)    │          │  (SQLiteデータベース)    │
└───────────┬─────────────┘          └─────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Ethereum Sepolia テストネット             │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   JPYC   │◄─│ JPYCWrapper  │─►│ Transfer10/Transfer5 │   │
│  └──────────┘  └──────────────┘  └──────────┬───────────┘   │
│                                              │               │
│                                              ▼               │
│                                  ┌──────────────────────┐   │
│                                  │     JAPointMint      │   │
│                                  │  ┌────────────────┐  │   │
│                                  │  │   JAPTトークン  │  │   │
│                                  │  └────────────────┘  │   │
│                                  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 技術スタック

### フロントエンド
| 技術 | 用途 |
|------|------|
| HTML/CSS/JavaScript | ユーザーインターフェース |
| ethers.js | Ethereum連携 (v5.7.2 モバイル, v6.9.0 デスクトップ) |
| QRCode.js | QRコード生成 |
| Cloudflare Pages | ホスティング |

### バックエンドAPI
| 技術 | 用途 |
|------|------|
| Cloudflare Workers | サーバーレスAPI |
| Cloudflare D1 | SQLiteデータベース |
| Wrangler | デプロイツール |

### スマートコントラクト
| 技術 | 用途 |
|------|------|
| Solidity ^0.8.20 | コントラクト言語 |
| OpenZeppelin | セキュリティライブラリ |
| Foundry | 開発・テスト |

### ネットワーク
| 項目 | 値 |
|------|-----|
| チェーン | Ethereum Sepolia テストネット |
| Chain ID | 11155111 |

## スマートコントラクト

### コントラクト概要

| コントラクト | 用途 | 手数料 |
|------------|------|--------|
| JPYC | 日本円ステーブルコイン（既存） | - |
| JAPT (JAPoint) | ポイントトークン（ERC20） | - |
| JPYCWrapper | JPYC転送に通知機能を追加 | - |
| Transfer10 | 決済処理 | 1% |
| Transfer5 | 決済処理 | 0.5% |
| JAPointMint | JAPTポイント配布 | - |

### デプロイ済みアドレス（Sepolia）

| コントラクト | アドレス |
|------------|---------|
| JAPT | `0xE477E1789F928facAA0f2513bA0d18345c97123D` |

その他のコントラクトアドレスはURLパラメータで設定されます。

## 決済フロー

1. 顧客がMetaMask MobileでQRコードをスキャン
2. URLパラメータにコントラクトアドレスを含むmobile-payment.htmlが開く
3. 顧客が金額を入力し「支払う」をタップ
4. JPYCのapproveトランザクション（MetaMaskで確認）
5. JPYCWrapper.transfer()が実行:
   - 1%/0.5%の手数料 → JAPointMint → 顧客にJAPT送付
   - 99%/99.5% → 店舗アドレスへ
6. API経由でD1データベースに決済を記録

## フロントエンドページ

| ファイル | 用途 |
|---------|------|
| `index.html` | 店舗ダッシュボード（QR生成、通知監視） |
| `mobile-payment.html` | 顧客用決済ページ（モバイル） |
| `dashboard.html` | 管理ダッシュボード（決済履歴、統計） |
| `add-japt.html` | JAPTをMetaMaskに追加 |

## APIエンドポイント

ベースURL: `https://japoint-api.kkuejo.workers.dev`

| メソッド | エンドポイント | 説明 |
|---------|--------------|------|
| POST | `/api/payments` | 決済を記録 |
| GET | `/api/payments` | 決済履歴を取得 |
| GET | `/api/payments/summary` | 集計サマリーを取得 |
| GET | `/api/payments/daily` | 日別サマリーを取得 |

## 開発

### 前提条件

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/)
- Node.js 18+

### スマートコントラクト開発

```bash
# コントラクトをビルド
forge build

# テストを実行
forge test

# Sepoliaにデプロイ
forge script script/DeployFullSystem.s.sol --rpc-url sepolia --broadcast
```

### Workers API開発

```bash
cd workers

# ローカル開発
wrangler dev

# デプロイ
wrangler deploy

# D1データベース操作
wrangler d1 execute japoint-payments --file=./schema.sql
```

### フロントエンドデプロイ

フロントエンドは`gh-pages`ブランチにプッシュすると自動的にCloudflare Pagesにデプロイされます。

## デプロイ情報

| サービス | URL / ID |
|---------|---------|
| Cloudflare Pages | https://japoint-payment.pages.dev |
| Cloudflare Workers | https://japoint-api.kkuejo.workers.dev |
| D1 Database | `15ff8ac7-fea5-491b-adf3-dcca95c5534c` |
| GitHub リポジトリ | kkuejo/japoint-payment |

## プロジェクト構成

```
.
├── src/                      # スマートコントラクト
│   ├── JAPoint.sol           # JAPTポイントトークン
│   ├── JAPointMint.sol       # JAPT配布
│   ├── JPYCWrapper.sol       # JPYC通知ラッパー
│   ├── Transfer10.sol        # 1%手数料決済処理
│   ├── Transfer5.sol         # 0.5%手数料決済処理
│   └── ITokenReceiver.sol    # 通知インターフェース
├── test/                     # コントラクトテスト
├── script/                   # デプロイスクリプト
├── workers/                  # Cloudflare Workers API
│   ├── src/index.js          # APIエンドポイント
│   ├── schema.sql            # D1データベーススキーマ
│   └── wrangler.toml         # Workers設定
├── index.html                # 店舗ダッシュボード
├── mobile-payment.html       # モバイル決済ページ
├── dashboard.html            # 管理ダッシュボード
├── add-japt.html             # JAPT MetaMask登録
└── system.md                 # システム詳細ドキュメント
```

## ドキュメント

- [system.md](system.md) - システムアーキテクチャと技術詳細
- [DEPLOYMENT.md](DEPLOYMENT.md) - デプロイ手順
- [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) - セットアップガイド

## ライセンス

MIT
