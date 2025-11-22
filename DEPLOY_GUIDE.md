# 🌐 インターネットへのデプロイガイド

## 📋 デプロイの全体像

1. **コントラクトをSepoliaテストネットにデプロイ**
2. **HTMLファイルをGitHub Pagesに公開**
3. **スマホからアクセス可能に！**

---

## 🚀 ステップ1: Sepoliaテストネットへのデプロイ

### 事前準備

#### 1. Sepolia ETHを取得

以下のFaucetから無料で取得できます：
- https://sepoliafaucet.com/
- https://www.infura.io/faucet/sepolia
- https://faucet.quicknode.com/ethereum/sepolia

#### 2. Alchemy APIキーを取得（無料）

1. https://www.alchemy.com/ にアクセス
2. サインアップ（無料）
3. 「Create App」をクリック
4. 以下を選択：
   - Chain: Ethereum
   - Network: Sepolia
5. APIキーをコピー

#### 3. .envファイルを作成

```bash
cp .env.example .env
```

`.env`ファイルを編集：

```env
# あなたのウォレットの秘密鍵
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE

# Alchemy RPC URL
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Etherscan API（オプション、コントラクト認証用）
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# 会社のウォレットアドレス
COMPANY_ADDRESS=0xYOUR_COMPANY_ADDRESS

# ショップのウォレットアドレス
SHOP_ADDRESS=0xYOUR_SHOP_ADDRESS
```

⚠️ **重要**: `.env`ファイルは絶対にGitにコミットしないでください！

### デプロイ実行

```bash
# Sepoliaテストネットにデプロイ
forge script script/DeployFullSystem.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvv

# または、環境変数を直接指定
forge script script/DeployFullSystem.s.sol \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY \
  --private-key YOUR_PRIVATE_KEY \
  --broadcast \
  --verify \
  -vvv
```

### デプロイ後のアドレスをメモ

デプロイが完了すると、以下のアドレスが表示されます：

```
JPYD deployed to: 0x...
JAPoint deployed to: 0x...
JAPointMint deployed to: 0x...
JPYDWrapper deployed to: 0x...
Transfer10 deployed to: 0x...
Transfer5 deployed to: 0x...
```

これらのアドレスをメモしてください！

---

## 🌐 ステップ2: GitHub Pagesへのデプロイ

### 方法A: GitHubのWeb UIを使用（簡単）

#### 1. GitHubリポジトリを作成

1. https://github.com/ にアクセス
2. 右上の「+」→「New repository」
3. リポジトリ名: `japoint-payment`（任意）
4. Public を選択
5. 「Create repository」をクリック

#### 2. 必要なファイルをアップロード

以下のファイルをGitHubリポジトリにアップロード：
- `index.html`
- `qr-codes-display.html`
- `mobile-payment.html`
- `frontend-example.html`
- `qr-generator.html`
- `MOBILE_ACCESS.md`
- `MOBILE_PAYMENT_GUIDE.md`

**ファイルのアップロード方法**:
1. リポジトリページで「Add file」→「Upload files」
2. ファイルをドラッグ&ドロップ
3. 「Commit changes」をクリック

#### 3. GitHub Pagesを有効化

1. リポジトリの「Settings」タブをクリック
2. 左サイドバーの「Pages」をクリック
3. Source: 「Deploy from a branch」を選択
4. Branch: 「main」を選択、フォルダ: 「/ (root)」
5. 「Save」をクリック

#### 4. 公開URLを確認

数分後、以下のURLで公開されます：
```
https://YOUR_USERNAME.github.io/japoint-payment/
```

---

### 方法B: Git CLIを使用（推奨）

#### 1. Gitリポジトリを初期化（まだの場合）

```bash
cd /home/kenichiuejo/src/JAPOINT

# Gitの設定
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# リポジトリ初期化
git init
```

#### 2. GitHub用のブランチを作成

```bash
# gh-pagesブランチを作成
git checkout -b gh-pages
```

#### 3. 必要なファイルだけをコミット

```bash
# HTMLファイルとドキュメントのみをステージング
git add index.html
git add qr-codes-display.html
git add mobile-payment.html
git add frontend-example.html
git add qr-generator.html
git add test-qr.html
git add *.md

# コミット
git commit -m "Deploy JAPOINT payment system to GitHub Pages"
```

#### 4. GitHubにプッシュ

```bash
# GitHubリポジトリを作成後、リモートを追加
git remote add origin https://github.com/YOUR_USERNAME/japoint-payment.git

# プッシュ
git push -u origin gh-pages
```

#### 5. GitHub Pagesを有効化

GitHubのリポジトリページで：
1. Settings → Pages
2. Source: Branch: `gh-pages` を選択
3. Save

---

## 🔧 ステップ3: HTMLファイルの更新

デプロイ後、Sepoliaのアドレスに更新する必要があります。

### 自動更新スクリプトを作成

```bash
cat > update-addresses.sh << 'EOF'
#!/bin/bash

# Sepoliaのコントラクトアドレス
JPYD_ADDRESS="0xYOUR_JPYD_ADDRESS"
WRAPPER_ADDRESS="0xYOUR_WRAPPER_ADDRESS"
TRANSFER10_ADDRESS="0xYOUR_TRANSFER10_ADDRESS"
TRANSFER5_ADDRESS="0xYOUR_TRANSFER5_ADDRESS"
JAPT_ADDRESS="0xYOUR_JAPT_ADDRESS"

# qr-codes-display.htmlを更新
sed -i "s/jpyd: '0x[^']*'/jpyd: '$JPYD_ADDRESS'/g" qr-codes-display.html
sed -i "s/wrapper: '0x[^']*'/wrapper: '$WRAPPER_ADDRESS'/g" qr-codes-display.html
sed -i "s/transfer10: '0x[^']*'/transfer10: '$TRANSFER10_ADDRESS'/g" qr-codes-display.html
sed -i "s/transfer5: '0x[^']*'/transfer5: '$TRANSFER5_ADDRESS'/g" qr-codes-display.html
sed -i "s/japt: '0x[^']*'/japt: '$JAPT_ADDRESS'/g" qr-codes-display.html

# frontend-example.htmlを更新
sed -i "s/jpyd: '0x[^']*'/jpyd: '$JPYD_ADDRESS'/g" frontend-example.html
sed -i "s/wrapper: '0x[^']*'/wrapper: '$WRAPPER_ADDRESS'/g" frontend-example.html
sed -i "s/transfer10: '0x[^']*'/transfer10: '$TRANSFER10_ADDRESS'/g" frontend-example.html
sed -i "s/transfer5: '0x[^']*'/transfer5: '$TRANSFER5_ADDRESS'/g" frontend-example.html
sed -i "s/japt: '0x[^']*'/japt: '$JAPT_ADDRESS'/g" frontend-example.html

echo "✅ アドレスを更新しました！"
EOF

chmod +x update-addresses.sh
```

### 実行

```bash
# アドレスを編集してから実行
nano update-addresses.sh
./update-addresses.sh
```

---

## 📱 ステップ4: スマホから使用

### MetaMask Mobileの設定

#### 1. ネットワークをSepoliaに変更

1. MetaMaskアプリを開く
2. 上部のネットワーク名をタップ
3. 「Sepolia test network」を選択

#### 2. トークンを追加

JPYD:
- アドレス: `0xYOUR_JPYD_ADDRESS`
- シンボル: JPYD
- 桁数: 18

JAPT:
- アドレス: `0xYOUR_JAPT_ADDRESS`
- シンボル: JAPT
- 桁数: 18

#### 3. アクセス

MetaMaskブラウザで以下を開く：
```
https://YOUR_USERNAME.github.io/japoint-payment/
```

---

## ✅ 完全な手順（まとめ）

```bash
# 1. .envファイルを設定
cp .env.example .env
nano .env

# 2. Sepoliaにデプロイ
forge script script/DeployFullSystem.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# 3. アドレスをメモして、HTMLを更新
nano update-addresses.sh
./update-addresses.sh

# 4. GitHubにプッシュ
git checkout -b gh-pages
git add *.html *.md
git commit -m "Deploy to GitHub Pages"
git remote add origin https://github.com/YOUR_USERNAME/japoint-payment.git
git push -u origin gh-pages

# 5. GitHub Pagesを有効化（Web UIで）

# 6. 完了！
# https://YOUR_USERNAME.github.io/japoint-payment/
```

---

## 🎯 代替案: Vercel（さらに簡単）

### Vercelを使う場合

1. https://vercel.com にアクセス
2. GitHubでサインアップ
3. 「New Project」をクリック
4. GitHubリポジトリを選択
5. 「Deploy」をクリック

→ 自動的にデプロイされます！

公開URL: `https://YOUR_PROJECT.vercel.app`

---

## 🆘 トラブルシューティング

### デプロイに失敗する

**原因**: Sepolia ETHが不足

**解決策**: Faucetから追加で取得

### GitHub Pagesが表示されない

**原因**: 設定が反映されていない

**解決策**:
- 数分待つ
- Settings → Pages で設定を確認
- ブランチが正しいか確認

### MetaMaskで接続できない

**原因**: ネットワークがSepoliaになっていない

**解決策**: MetaMaskのネットワークをSepoliaに切り替え

---

次のステップに進みますか？デプロイを開始しましょう！🚀
