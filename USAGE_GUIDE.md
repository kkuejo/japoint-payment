# JAPOINT システム使用ガイド

## 📱 モバイル決済（最も簡単）

JAPOINTシステムは既にSepoliaテストネットにデプロイ済みです。

### クイックスタート

1. **MetaMask Mobileで以下のURLを開く**:
   ```
   https://kkuejo.github.io/japoint-payment/mobile-payment.html?shop=テストショップ（1%）&type=transfer10&jpyd=0xdD870D138DC6081E664c5127226e815cc4C6f87D&wrapper=0xa30042F978913cE9B466e204E7F729AeBCb3c624&target=0xA3963E928B35Ac06cC519b2a1BbBc3F27aCf0460&japt=0x2eDf302548B23e9F599e483aE79cda6D8774c6fC
   ```

2. **「MetaMaskで接続」をタップ**

3. **金額を入力して「支払う」をタップ**

4. **署名を承認** → 完了！JAPTが自動的に付与されます

---

## 💻 MetaMaskから送金する方法

### 事前準備

1. **MetaMaskをインストール**
   - https://metamask.io/ からインストール

2. **Sepoliaネットワークを追加**
   - ネットワーク名: Sepolia Test Network
   - RPC URL: https://ethereum-sepolia-rpc.publicnode.com
   - チェーンID: 11155111
   - 通貨記号: ETH
   - Block Explorer: https://sepolia.etherscan.io

3. **Sepolia ETHを取得**
   - Faucet: https://sepoliafaucet.com/

4. **JPYDトークンをMetaMaskに追加**
   - MetaMaskで「トークンをインポート」
   - トークンアドレス: `0xdD870D138DC6081E664c5127226e815cc4C6f87D`
   - シンボル: JPYD
   - 小数点: 18

5. **JAPTトークンをMetaMaskに追加**
   - トークンアドレス: `0x2eDf302548B23e9F599e483aE79cda6D8774c6fC`
   - シンボル: JAPT
   - 小数点: 18

---

## 送金方法（2つの方法があります）

### 方法1: JPYDWrapper経由（推奨・完全自動）

**特徴**: Transfer5またはTransfer10を選択して、完全に自動化された送金が可能

**手順**:

1. **Approve**: JPYDトークンをJPYDWrapperに承認
   ```javascript
   // JPYDコントラクトで実行
   approve(JPYDWrapperアドレス, 送金額)
   ```

2. **Transfer**: JPYDWrapperを使ってTransfer5/10に送金
   ```javascript
   // JPYDWrapperコントラクトで実行
   transfer(Transfer10またはTransfer5のアドレス, 送金額)
   ```

3. **自動処理**: 以下が自動的に実行されます
   - Transfer10の場合:
     - 99%がショップに送金
     - 1%が会社に送金
     - 1%相当のJAPTがユーザーに付与
   - Transfer5の場合:
     - 99.5%がショップに送金
     - 0.5%が会社に送金
     - 0.5%相当のJAPTがユーザーに付与

**コード例（ethers.js）**:
```javascript
// 1. Approve
const jpyd = new ethers.Contract(jpydAddress, jpydABI, signer);
const approvalTx = await jpyd.approve(wrapperAddress, ethers.utils.parseEther("100"));
await approvalTx.wait();

// 2. Transfer
const wrapper = new ethers.Contract(wrapperAddress, wrapperABI, signer);
const transferTx = await wrapper.transfer(transfer10Address, ethers.utils.parseEther("100"));
await transferTx.wait();

console.log("完了！JAPTを受け取りました！");
```

---

### 方法2: Transfer10に直接Deposit

**特徴**: Transfer10のdepositメソッドを直接呼び出す

**手順**:

1. **Approve**: JPYDトークンをTransfer10に承認
   ```javascript
   // JPYDコントラクトで実行
   approve(Transfer10アドレス, 送金額)
   ```

2. **Deposit**: Transfer10のdepositメソッドを呼び出す
   ```javascript
   // Transfer10コントラクトで実行
   deposit(送金額)
   ```

3. **自動処理**: 以下が自動的に実行されます
   - 99%がショップに送金
   - 1%が会社に送金
   - 1%相当のJAPTがユーザーに付与

**コード例（ethers.js）**:
```javascript
// 1. Approve
const jpyd = new ethers.Contract(jpydAddress, jpydABI, signer);
const approvalTx = await jpyd.approve(transfer10Address, ethers.utils.parseEther("100"));
await approvalTx.wait();

// 2. Deposit
const transfer10 = new ethers.Contract(transfer10Address, transfer10ABI, signer);
const depositTx = await transfer10.deposit(ethers.utils.parseEther("100"));
await depositTx.wait();

console.log("完了！JAPTを受け取りました！");
```

---

## HTMLインターフェースの使い方

`frontend-example.html` ファイルをブラウザで開いて使用できます。

### 手順

1. **ファイルを開く**
   ```bash
   # ブラウザでfrontend-example.htmlを開く
   open frontend-example.html  # macOS
   # または
   firefox frontend-example.html  # Linux
   ```

2. **MetaMaskを接続**
   - 「MetaMask接続」ボタンをクリック

3. **コントラクトアドレスを設定**
   - デプロイしたコントラクトのアドレスを入力
   - 「アドレスを保存」をクリック

4. **残高を確認**
   - 「残高を確認」ボタンで現在の保有量を確認

5. **送金を実行**
   - 方法Aまたは方法Bを選択
   - 金額を入力
   - 「Approve」→「送金実行」の順にクリック

---

## 📦 既存のSepoliaデプロイメント

すぐに使用できるコントラクトアドレス：

| コントラクト | アドレス |
|------------|---------|
| **JPYD** | `0xdD870D138DC6081E664c5127226e815cc4C6f87D` |
| **JAPoint** | `0x2eDf302548B23e9F599e483aE79cda6D8774c6fC` |
| **JPYDWrapper** | `0xa30042F978913cE9B466e204E7F729AeBCb3c624` |
| **Transfer10** | `0xA3963E928B35Ac06cC519b2a1BbBc3F27aCf0460` |
| **Transfer5** | `0x74F6CfD89751a677E74130752483a530e27D4819` |

詳細: [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 🚀 新しくデプロイする場合

### 1. 環境変数を設定

`.env`ファイルを作成:
```bash
cp .env.example .env
```

`.env`を編集:
```
PRIVATE_KEY=あなたの秘密鍵
COMPANY_ADDRESS=会社のウォレットアドレス
SHOP_ADDRESS=ショップのウォレットアドレス
```

### 2. デプロイを実行

```bash
source .env

# Sepoliaテストネットにデプロイ
forge script script/DeployFullSystem.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --slow \
  --legacy
```

詳細な手順: [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)

---

## よくある質問

### Q1. なぜJPYDWrapperが必要なのですか？

A: JPYDとJPYCは標準的なERC20トークンで、転送時の自動通知機能がありません。JPYDWrapperを使うことで、トークン転送時に受信者（Transfer5/10）に自動通知され、完全に自動化された処理が可能になります。

### Q2. Transfer5とTransfer10の違いは？

A: 手数料率が異なります:
- **Transfer5**: 0.5%手数料（99.5%がショップへ）
- **Transfer10**: 1%手数料（99%がショップへ）

### Q3. 直接JPYDをTransfer10に送ったらどうなりますか？

A: MetaMaskで直接`transfer()`を使って送った場合、トークンは送られますが自動処理は実行されません。その場合は`processDirectTransfer()`または`processAllDirectTransfer()`を手動で呼び出す必要があります。

### Q4. ガス代はどれくらいかかりますか？

A: ネットワークの混雑状況によりますが、大体:
- Approve: 約50,000 gas
- Transfer/Deposit: 約200,000-300,000 gas

### Q5. トランザクションが失敗しました

A: 以下を確認してください:
- JPYDの残高は十分にありますか？
- Approveは完了していますか？
- ガス代（ETH）は十分にありますか？
- 正しいコントラクトアドレスを使用していますか？

---

## セキュリティ注意事項

⚠️ **重要**:
- 秘密鍵は絶対に公開しないでください
- `.env`ファイルはGitにコミットしないでください
- 本番環境では必ず信頼できるRPCプロバイダーを使用してください
- スマートコントラクトのアドレスは必ず複数回確認してください

---

## サポート

問題が発生した場合は、以下を確認してください:
1. トランザクションハッシュ
2. 使用したアドレス
3. エラーメッセージ

テストを実行:
```bash
# すべてのテストを実行
forge test -vv

# 特定のテストを実行
forge test --match-test testAutomaticProcessing -vvv
```
