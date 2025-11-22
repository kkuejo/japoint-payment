# 🚀 Sepoliaデプロイ - セットアップ手順

## 📋 必要な準備

### 1. Sepolia ETHを取得

以下のいずれかのFaucetから無料で取得してください：

- **Alchemy Faucet**: https://sepoliafaucet.com/
- **Infura Faucet**: https://www.infura.io/faucet/sepolia
- **QuickNode Faucet**: https://faucet.quicknode.com/ethereum/sepolia

最低でも **0.5 ETH**（Sepolia）が必要です。

---

### 2. Alchemy APIキーを取得（無料）

#### 手順:

1. https://www.alchemy.com/ にアクセス
2. 「Sign Up」をクリック
3. 無料アカウントを作成
4. ダッシュボードで「Create App」をクリック
5. 以下を選択：
   - Chain: **Ethereum**
   - Network: **Sepolia**
   - App Name: JAPOINT（任意）
6. 作成後、「View Key」をクリック
7. **HTTPS URL**をコピー
   - 例: `https://eth-sepolia.g.alchemy.com/v2/abcd1234...`

---

### 3. ウォレット情報を準備

#### デプロイ用ウォレット:
- MetaMaskの秘密鍵（デプロイに使用）
- Sepolia ETHが入っている必要があります

**秘密鍵の取得方法** (MetaMask):
1. MetaMaskを開く
2. アカウント詳細をクリック
3. 「秘密鍵のエクスポート」をクリック
4. パスワードを入力
5. 秘密鍵をコピー（例: `0xabcd1234...`）

⚠️ **絶対に秘密鍵を公開しないでください！**

#### 会社アドレス:
- 手数料を受け取るウォレットアドレス
- 例: `0x1234...`

#### ショップアドレス:
- 売上を受け取るウォレットアドレス
- 例: `0x5678...`

---

## 🔧 .envファイルの作成

### 方法1: 対話型スクリプト（簡単）

```bash
cd /home/kenichiuejo/src/JAPOINT
./setup-env.sh
```

スクリプトが質問に答えるだけで.envファイルを作成します。

---

### 方法2: 手動作成

```bash
cd /home/kenichiuejo/src/JAPOINT

# .env.exampleをコピー
cp .env.example .env

# エディタで編集
nano .env
```

`.env`ファイルの内容:

```env
# デプロイ用ウォレットの秘密鍵
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE

# Alchemy RPC URL
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Etherscan API key（オプション、コントラクト認証用）
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# 会社のウォレットアドレス（手数料受取先）
COMPANY_ADDRESS=0xYOUR_COMPANY_ADDRESS

# ショップのウォレットアドレス（売上受取先）
SHOP_ADDRESS=0xYOUR_SHOP_ADDRESS

# 初期JPYD供給量（オプション）
INITIAL_JPYD_SUPPLY=10000000000000000000000000
```

保存: Ctrl+O → Enter → Ctrl+X

---

## ✅ 設定確認

```bash
# .envファイルが存在するか確認
ls -la .env

# 内容を確認（秘密鍵は表示されないように注意）
cat .env
```

---

## 🚀 デプロイ実行

設定が完了したら、以下のコマンドでデプロイできます：

```bash
source .env

forge script script/DeployFullSystem.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvv
```

デプロイには数分かかります。完了すると、以下のアドレスが表示されます：

```
JPYD deployed to: 0x...
JAPoint deployed to: 0x...
JAPointMint deployed to: 0x...
JPYDWrapper deployed to: 0x...
Transfer10 deployed to: 0x...
Transfer5 deployed to: 0x...
```

**これらのアドレスを必ずメモしてください！**

---

## 📝 チェックリスト

デプロイ前に以下を確認：

- [ ] Sepolia ETHを取得済み（最低0.5 ETH）
- [ ] Alchemy APIキーを取得済み
- [ ] デプロイ用ウォレットの秘密鍵を確認済み
- [ ] 会社アドレスを決定済み
- [ ] ショップアドレスを決定済み
- [ ] `.env`ファイルを作成済み
- [ ] `.env`がGitに含まれていないことを確認（`.gitignore`に記載）

---

準備ができたら、次のステップに進みましょう！
