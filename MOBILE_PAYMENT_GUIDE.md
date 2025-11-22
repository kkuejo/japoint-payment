# 📱 モバイル決済ガイド - JAPOINT

## 概要

**1つのQRコードで完結！** ユーザーは金額を入力して承認するだけで決済が完了します。

### 特徴

✅ **1回の承認で完了** - ApproveとTransferを1つのトランザクションで実行
✅ **EIP-2612 Permit使用** - オフチェーン署名でガス代を節約
✅ **モバイル最適化** - MetaMask Mobileで快適に動作
✅ **QRコード対応** - スキャンするだけで決済ページへ
✅ **自動ポイント付与** - JAPTが即座にウォレットに

---

## 🚀 クイックスタート

### 1. ファイル構成

```
JAPOINT/
├── mobile-payment.html   # モバイル決済ページ
├── qr-generator.html     # QRコード生成ツール
└── MOBILE_PAYMENT_GUIDE.md  # このガイド
```

### 2. デプロイ（前提条件）

まず、コントラクトをデプロイします：

```bash
# ローカルテスト
anvil  # 別ターミナルで実行
forge script script/DeployFullSystem.s.sol --rpc-url http://localhost:8545 --broadcast

# Sepoliaテストネット
forge script script/DeployFullSystem.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

デプロイ後、以下のアドレスをメモしてください：
- JPYD
- JPYDWrapper
- Transfer10
- Transfer5
- JAPoint

### 3. 決済ページの公開

**オプションA: GitHub Pagesを使用（簡単・推奨）**

1. GitHubリポジトリを作成
2. `mobile-payment.html` をpushする
3. Settings → Pages → Source を "main branch" に設定
4. 公開URL: `https://yourusername.github.io/japoint/mobile-payment.html`

**オプションB: 自分のサーバー**

```bash
# Webサーバーにアップロード
scp mobile-payment.html user@yourserver.com:/var/www/html/

# URL: https://yourdomain.com/mobile-payment.html
```

**オプションC: ローカルテスト（開発用）**

```bash
# Pythonの簡易サーバーを使用
python3 -m http.server 8000

# ブラウザで開く: http://localhost:8000/mobile-payment.html
```

### 4. QRコード生成

1. ブラウザで `qr-generator.html` を開く
2. コントラクトアドレスを入力
3. Base URL（決済ページのURL）を入力
4. ショップ名と手数料率を選択
5. 「QRコードを生成」をクリック
6. QRコードをダウンロードまたは印刷

---

## 💳 お客様（ユーザー）の使い方

### スマートフォンから決済

1. **QRコードをスキャン**
   - MetaMask Mobileアプリのブラウザで開く
   - またはカメラでQRコードをスキャン

2. **MetaMaskで接続**
   - 「MetaMaskで接続」ボタンをタップ
   - ウォレットを選択して接続

3. **金額を入力**
   - 支払い金額を入力（JPYD）
   - 内訳が自動表示される：
     - ショップ受取額
     - 手数料
     - 獲得ポイント（JAPT）

4. **支払いを実行**
   - 「支払う」ボタンをタップ
   - 署名を承認（**1回のみ**）
   - 完了！JAPTポイントが自動的に付与されます

### 仕組み（技術的な説明）

```
ユーザーの操作：
1. 金額入力
2. 「支払う」をタップ
3. 署名を承認（1回）

自動処理（バックグラウンド）：
1. EIP-712署名作成（オフチェーン、ガス不要）
2. transferWithPermit()を呼び出し
   ├─ Permit実行（Approve）
   └─ Transfer実行
3. Transfer5/10が自動処理
   ├─ 99.5%/99% → ショップ
   ├─ 0.5%/1% → JAPointMint → 会社
   └─ 0.5%/1%相当のJAPT → ユーザー
```

---

## 🏪 ショップオーナー向け

### QRコードの設置方法

1. **レジカウンターに設置**
   - A4サイズに印刷
   - ラミネート加工推奨
   - 目立つ場所に配置

2. **テーブルに設置**
   - 各テーブルに小さいQRコード
   - テーブル番号を含めることも可能

3. **デジタルサイネージ**
   - タブレットやディスプレイで表示
   - QRコードを大きく表示

### 受け取り先の設定

デプロイ時に設定したアドレスで受け取ります：

```bash
# .envファイルで設定
SHOP_ADDRESS=0xYourShopWalletAddress
COMPANY_ADDRESS=0xYourCompanyWalletAddress
```

- **SHOP_ADDRESS**: 売上金（99%または99.5%）の受取先
- **COMPANY_ADDRESS**: 手数料（1%または0.5%）の受取先

### 手数料率の選択

| コントラクト | 手数料率 | ショップ受取 | JAPT還元率 |
|------------|---------|------------|-----------|
| Transfer5  | 0.5%    | 99.5%      | 0.5%      |
| Transfer10 | 1%      | 99%        | 1%        |

**推奨**: まずTransfer10（1%）でテストし、必要に応じてTransfer5を追加

---

## 🔧 高度な設定

### カスタムドメイン

独自ドメインを使用する場合：

1. DNS設定でAレコードを追加
2. SSL証明書を設定（Let's Encrypt推奨）
3. `qr-generator.html`のBase URLに設定

例: `https://pay.yourshop.com/mobile-payment.html`

### URLパラメータ

決済ページのURLパラメータ：

| パラメータ | 必須 | 説明 | 例 |
|----------|-----|------|-----|
| shop | ✓ | ショップ名 | `shop=カフェ山田` |
| type | ✓ | コントラクトタイプ | `type=transfer10` |
| jpyd | ✓ | JPYDアドレス | `jpyd=0x...` |
| wrapper | ✓ | JPYDWrapperアドレス | `wrapper=0x...` |
| target | ✓ | Transfer5/10アドレス | `target=0x...` |
| japt |  | JAPTアドレス | `japt=0x...` |

完全なURL例：
```
https://yourdomain.com/mobile-payment.html?shop=カフェ山田&type=transfer10&jpyd=0x0355B7B8cb128fA5692729Ab3AAa199C1753f726&wrapper=0x172076E0166D1F9Cc711C77Adf8488051744980C&target=0x4EE6eCAD1c2Dae9f525404De8555724e3c35d07B&japt=0x202CCe504e04bEd6fC0521238dDf04Bc9E8E15aB
```

### デザインのカスタマイズ

`mobile-payment.html`のCSSを編集して、ショップのブランドに合わせてカスタマイズできます：

```css
/* 色を変更 */
body {
    background: linear-gradient(135deg, #YOUR_COLOR1 0%, #YOUR_COLOR2 100%);
}

.pay-button {
    background: linear-gradient(135deg, #YOUR_COLOR1 0%, #YOUR_COLOR2 100%);
}
```

---

## 🧪 テスト手順

### ローカル環境でテスト

1. **Anvilを起動**
```bash
anvil
```

2. **コントラクトをデプロイ**
```bash
forge script script/TestAutomation.s.sol --rpc-url http://localhost:8545 --broadcast
```

3. **アドレスをメモ**
コンソールに表示されるアドレスをコピー

4. **MetaMask設定**
- ネットワーク追加: Anvil Local
- RPC URL: http://localhost:8545
- Chain ID: 31337
- Anvilのテストアカウントをインポート

5. **QRコード生成**
- `qr-generator.html`を開く
- Base URL: `file:///path/to/mobile-payment.html` （フルパス）
- アドレスを入力して生成

6. **モバイルで確認**
- 生成されたURLをスマホに送信
- MetaMask Mobileで開く
- テスト決済を実行

### Sepoliaテストネットでテスト

1. **SepoliaのETHを取得**
- https://sepoliafaucet.com/

2. **デプロイ**
```bash
forge script script/DeployFullSystem.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

3. **JPYDをMint**
デプロイアカウントからテスト用ウォレットにJPYDを送信

4. **モバイルでテスト**
実際のスマートフォンで動作確認

---

## 🔐 セキュリティ

### 重要な注意事項

⚠️ **絶対にしないこと**:
- 秘密鍵をコードに含めない
- HTTPSなしで本番運用しない
- テストが不十分なままメインネットにデプロイしない

✅ **推奨事項**:
- 必ずHTTPS（SSL）を使用
- コントラクトアドレスを複数回確認
- テストネットで十分にテスト
- 監査を受ける（本番環境）
- マルチシグウォレットを使用（大きな金額の場合）

### Permit署名の安全性

EIP-2612のPermit機能は：
- ✅ EIP-712で標準化された署名方式
- ✅ 有効期限（deadline）付き
- ✅ Nonce（使用済み防止）
- ✅ Domain Separator（チェーン分離）

で保護されています。

---

## 📊 トランザクションの流れ

### 詳細なフロー

```
ユーザー
  ↓
① 署名作成（オフチェーン、ガス代なし）
  ↓
② JPYDWrapper.transferWithPermit()
  ├─ JPYD.permit() ← 署名を検証
  │   └─ allowance設定完了
  └─ JPYDWrapper.transfer()
      └─ Transfer10.onTokenReceived()
          ├─ JPYD 99% → shopAddress
          ├─ JPYD 1% → JAPointMint
          └─ JAPointMint.transferJAPoint()
              ├─ JAPT 1%相当 → ユーザー
              └─ JPYD 1% → companyAddress
```

### ガス代

| 処理 | ガス代 | 誰が負担 |
|-----|-------|---------|
| 署名作成 | 0 | なし（オフチェーン） |
| transferWithPermit() | 約250,000 gas | ユーザー |

**1回のトランザクションで全て完了！**

---

## 🎯 よくある質問

### Q1. なぜPermitが必要なのですか？

A: Permitを使うことで、ApproveとTransferを1つのトランザクションにまとめることができます。ユーザーは1回の承認だけで済み、UXが大幅に向上します。

### Q2. HTTPSは必須ですか？

A: 本番環境では**必須**です。MetaMaskはHTTPSでないとWeb3機能を提供しません。ローカルテストではHTTPも使用できます。

### Q3. QRコードの有効期限はありますか？

A: QRコード自体に有効期限はありません。ただし、コントラクトアドレスが変更された場合は新しいQRコードが必要です。

### Q4. オフラインでも動作しますか？

A: いいえ、ブロックチェーンへの接続が必要です。ユーザーはインターネット接続が必要です。

### Q5. 複数のショップで同じQRコードを使えますか？

A: いいえ、各ショップごとにQRコードを生成してください。ショップ名がURLパラメータに含まれます。

### Q6. 決済が失敗した場合は？

A: 以下を確認してください：
- JPYD残高は十分か
- ETH（ガス代）は十分か
- 正しいネットワークに接続しているか
- コントラクトアドレスは正しいか

---

## 🆘 トラブルシューティング

### 署名エラーが出る

**原因**: MetaMaskが署名をサポートしていない、または拒否された

**解決策**:
1. MetaMask Mobileを最新版に更新
2. ネットワーク設定を確認
3. 再度試す

### トランザクションが失敗する

**原因**: ガス不足、残高不足、コントラクトエラー

**解決策**:
1. ETH（ガス代）の残高を確認
2. JPYD残高を確認
3. Etherscanでトランザクションを確認
4. エラーメッセージを確認

### QRコードが読み取れない

**原因**: 画質が悪い、サイズが小さい

**解決策**:
1. より大きいサイズで印刷
2. 高解像度で出力
3. 直接URLをコピーして使用

---

## 📞 サポート

問題が発生した場合：

1. トランザクションハッシュを確認
2. エラーメッセージをスクリーンショット
3. 使用したネットワーク（Sepolia、Mainnetなど）を確認
4. コントラクトアドレスを再確認

テストの実行：
```bash
forge test -vv
```

---

## 🎉 まとめ

これで、モバイルからのJAPOINT決済システムが完成しました！

**ユーザーは**:
1. QRコードをスキャン
2. 金額を入力
3. 1回承認するだけ

**自動的に**:
- ショップに売上が入金
- 会社に手数料が入金
- ユーザーにJAPTポイントが付与

シンプル、高速、安全な決済システムです！
