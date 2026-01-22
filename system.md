# JAPOINT システム概要

## システム概要

JAPOINTは、JPYC（日本円ステーブルコイン）を使用したポイント還元型決済システムです。顧客がJPYCで支払いを行うと、手数料の一部がJAPT（JAPoint）トークンとして還元されます。

## アーキテクチャ図

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          フロントエンド (Cloudflare Pages)                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  index.html  │  │mobile-payment│  │ dashboard.html│  │  add-japt   │  │
│  │  (店舗用)    │  │    .html     │  │  (管理画面)   │  │    .html    │  │
│  │  QR生成      │  │  (顧客用)    │  │  決済履歴     │  │ トークン登録│  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────────────┘  │
│         │                 │                 │                            │
└─────────┼─────────────────┼─────────────────┼────────────────────────────┘
          │                 │                 │
          │                 ▼                 │
          │    ┌────────────────────────┐     │
          │    │   MetaMask Mobile      │     │
          │    │   (ユーザーウォレット)  │     │
          │    └───────────┬────────────┘     │
          │                │                  │
          ▼                ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Cloudflare Workers API                             │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  japoint-api.kkuejo.workers.dev                                    │ │
│  │  - POST /api/payments     (決済記録)                               │ │
│  │  - GET  /api/payments     (履歴取得)                               │ │
│  │  - GET  /api/payments/summary (集計)                               │ │
│  │  - GET  /api/payments/daily   (日別)                               │ │
│  └───────────────────────────────┬────────────────────────────────────┘ │
│                                  │                                      │
│                                  ▼                                      │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  Cloudflare D1 (SQLite)                                            │ │
│  │  - payments テーブル (取引履歴)                                    │ │
│  │  - daily_summary テーブル (日別集計)                               │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    Sepolia Testnet (Ethereum L2)                        │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  スマートコントラクト群                                            │ │
│  │                                                                    │ │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │ │
│  │  │    JPYC     │    │  JPYCWrapper │    │   JAPoint    │          │ │
│  │  │  (既存ERC20)│◄───│  (ラッパー)   │    │   (JAPT)    │          │ │
│  │  │             │    │  通知機能追加 │    │   ERC20      │          │ │
│  │  └──────────────┘    └──────┬───────┘    └──────┬───────┘          │ │
│  │                             │                   │                  │ │
│  │                             ▼                   │                  │ │
│  │  ┌──────────────────────────────────────────────┼───────────────┐  │ │
│  │  │              Transfer10 / Transfer5          │               │  │ │
│  │  │  ┌─────────────────────────────────────────┐ │               │  │ │
│  │  │  │ onTokenReceived() で自動処理            │ │               │  │ │
│  │  │  │ - 手数料(1%/0.5%)をJAPointMintへ        │ │               │  │ │
│  │  │  │ - 残り(99%/99.5%)を店舗アドレスへ       │ │               │  │ │
│  │  │  └─────────────────────────────────────────┘ │               │  │ │
│  │  └──────────────────────────────────────────────┼───────────────┘  │ │
│  │                             │                   │                  │ │
│  │                             ▼                   │                  │ │
│  │  ┌──────────────────────────────────────────────▼───────────────┐  │ │
│  │  │                    JAPointMint                               │  │ │
│  │  │  - JPYCを受け取り、同額のJAPTを顧客に送付                    │  │ │
│  │  │  - JPYCは会社アドレスに転送                                  │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## 技術スタック

### フロントエンド
| 技術 | 用途 | バージョン |
|------|------|-----------|
| HTML/CSS/JavaScript | UI | - |
| ethers.js | Ethereum連携 | v5.7.2 (mobile), v6.9.0 (index) |
| QRCode.js | QRコード生成 | v1.4.4 |
| Cloudflare Pages | ホスティング | - |

### バックエンド API
| 技術 | 用途 | 備考 |
|------|------|------|
| Cloudflare Workers | サーバーレスAPI | Node.js互換 |
| Cloudflare D1 | SQLiteデータベース | サーバーレス |
| Wrangler | デプロイツール | v3.x |

### スマートコントラクト
| 技術 | 用途 | バージョン |
|------|------|-----------|
| Solidity | コントラクト言語 | ^0.8.20 |
| OpenZeppelin | セキュリティライブラリ | - |
| Foundry | 開発・デプロイ | - |

### ネットワーク
| 項目 | 値 |
|------|-----|
| チェーン | Ethereum Sepolia Testnet |
| Chain ID | 11155111 |
| ブロックタイム | ~12秒 |

## スマートコントラクト

### デプロイ済みアドレス (Sepolia)

| コントラクト | アドレス |
|-------------|---------|
| JPYC (テスト用) | URLパラメータで指定 |
| JAPT (JAPoint) | `0xE477E1789F928facAA0f2513bA0d18345c97123D` |
| JPYCWrapper | URLパラメータで指定 |
| Transfer10 | URLパラメータで指定 |
| Transfer5 | URLパラメータで指定 |
| JAPointMint | URLパラメータで指定 |

### コントラクト構成

#### 1. JAPoint.sol (JAPT)
- 標準ERC20トークン
- ポイント還元用トークン
- 初期供給量はJAPointMintコントラクトに保持

#### 2. JPYCWrapper.sol
- JPYCトークンのラッパーコントラクト
- `transfer()` - トークン転送 + 受信者への通知
- `transferWithPermit()` - EIP-2612 Permit対応（現在未使用）
- `ITokenReceiver` インターフェースで受信コントラクトに通知

#### 3. Transfer10.sol / Transfer5.sol
- 決済処理コントラクト（手数料率: 1% / 0.5%）
- `onTokenReceived()` - JPYCWrapper経由の自動処理
- `deposit()` - approve後の手動決済
- 手数料をJAPointMintへ、残りを店舗へ転送

#### 4. JAPointMint.sol
- JPYCを受け取り、同額のJAPTを顧客に配布
- JPYCは会社アドレスへ転送
- JAPTリザーブを保持

## 決済フロー

```
1. 顧客がQRコードをスキャン
   └─> MetaMask Mobileブラウザでmobile-payment.htmlを開く

2. 顧客が金額を入力して「支払う」をタップ
   └─> MetaMask接続要求

3. JPYCのapprove（承認）
   └─> 顧客がMetaMaskで承認

4. JPYCWrapper.transfer()実行
   └─> Transfer10/Transfer5コントラクトへJPYC送金
   └─> onTokenReceived()が自動発火

5. 自動処理
   ├─> 1%/0.5% → JAPointMint → 顧客にJAPT送付
   └─> 99%/99.5% → 店舗アドレスに送金

6. フロントエンドがAPI経由で決済を記録
   └─> Cloudflare D1に保存
```

## フロントエンド構成

### ファイル一覧

| ファイル | 用途 |
|---------|------|
| `index.html` | 店舗用メイン画面（QRコード生成、通知監視） |
| `mobile-payment.html` | 顧客用決済画面（スマホ用） |
| `dashboard.html` | 管理ダッシュボード（決済履歴、統計） |
| `add-japt.html` | JAPTトークンをMetaMaskに登録 |
| `qr-codes-display.html` | QRコード表示（印刷用） |
| `qr-generator.html` | QRコード生成ツール |

### URL構成

#### mobile-payment.html パラメータ
```
?shop=ショップ名
&type=transfer10|transfer5
&jpyd=JPYCアドレス
&wrapper=JPYCWrapperアドレス
&target=Transfer10/5アドレス
&japt=JAPTアドレス
```

## API エンドポイント

### ベースURL
- 本番: `https://japoint-api.kkuejo.workers.dev`
- ローカル: `http://localhost:8787`

### エンドポイント一覧

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/api/health` | ヘルスチェック |
| POST | `/api/payments` | 決済を記録 |
| GET | `/api/payments` | 決済履歴を取得（フィルタ対応） |
| GET | `/api/payments/summary` | 集計サマリーを取得 |
| GET | `/api/payments/daily` | 日別サマリーを取得 |

### POST /api/payments リクエスト例
```json
{
  "txHash": "0x...",
  "senderAddress": "0x...",
  "shopAddress": "0x...",
  "companyAddress": "0x...",
  "totalAmount": "1000",
  "shopAmount": "990",
  "companyAmount": "10",
  "japtAmount": "10",
  "planType": "transfer10",
  "blockNumber": 12345678,
  "blockTimestamp": 1700000000
}
```

## データベーススキーマ

### payments テーブル
| カラム | 型 | 説明 |
|--------|-----|------|
| id | INTEGER | 主キー |
| tx_hash | TEXT | トランザクションハッシュ（UNIQUE） |
| sender_address | TEXT | 送金者アドレス |
| shop_address | TEXT | 店舗アドレス |
| company_address | TEXT | 会社アドレス |
| total_amount | TEXT | 総額（JPYC） |
| shop_amount | TEXT | 店舗受取額 |
| company_amount | TEXT | 会社受取額 |
| japt_amount | TEXT | JAPT付与額 |
| plan_type | TEXT | プラン種別 |
| block_number | INTEGER | ブロック番号 |
| block_timestamp | INTEGER | ブロックタイムスタンプ |
| created_at | TEXT | 作成日時 |

### daily_summary テーブル
| カラム | 型 | 説明 |
|--------|-----|------|
| id | INTEGER | 主キー |
| date | TEXT | 日付 |
| plan_type | TEXT | プラン種別 |
| total_transactions | INTEGER | 取引数 |
| total_jpyc | TEXT | 総額（JPYC） |
| total_japt | TEXT | 総JAPT |
| total_shop_revenue | TEXT | 店舗売上合計 |
| total_company_revenue | TEXT | 会社売上合計 |

## デプロイ情報

### Cloudflare

| サービス | URL / ID |
|---------|---------|
| Pages (フロントエンド) | https://japoint-payment.pages.dev |
| Workers (API) | https://japoint-api.kkuejo.workers.dev |
| D1 Database ID | `15ff8ac7-fea5-491b-adf3-dcca95c5534c` |
| アカウント | kkuejo@yahoo.co.jp |

### GitHub

| 項目 | 値 |
|------|-----|
| リポジトリ | kkuejo/japoint-payment |
| ブランチ | gh-pages |

## 開発コマンド

### Cloudflare Workers
```bash
cd workers

# ローカル開発
wrangler dev

# デプロイ
wrangler deploy

# D1操作
wrangler d1 execute japoint-payments --file=./schema.sql
wrangler d1 execute japoint-payments --command="SELECT * FROM payments"

# ログ確認
wrangler tail
```

### スマートコントラクト
```bash
# ビルド
forge build

# テスト
forge test

# デプロイ
forge script script/DeployFullSystem.s.sol --rpc-url sepolia --broadcast
```

## セキュリティ考慮事項

1. **フロントエンド**
   - CORSによるオリジン制限
   - MetaMaskによる署名検証

2. **API**
   - ALLOWED_ORIGINSで許可オリジンを制限
   - tx_hashのUNIQUE制約で重複記録防止

3. **スマートコントラクト**
   - OpenZeppelinのOwnable/IERC20使用
   - recoverTokens()で緊急時のトークン回収可能
   - require()による入力検証

## 今後の拡張予定

- [ ] Polygon Mainnetへの移行（高速化）
- [ ] 本番JPYC対応
- [ ] 管理者認証機能
- [ ] Webhook通知
