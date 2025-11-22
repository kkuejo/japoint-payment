# JAPOINT システム使用ガイド

## メタマスクから送金する方法

### 事前準備

1. **MetaMaskをインストール**
   - https://metamask.io/ からインストール

2. **ネットワークを追加**（ローカルテストの場合）
   - ネットワーク名: Anvil Local
   - RPC URL: http://localhost:8545
   - チェーンID: 31337
   - 通貨記号: ETH

3. **JPYDトークンをMetaMaskに追加**
   - MetaMaskで「トークンをインポート」
   - トークンコントラクトアドレス: （デプロイ後のJPYDアドレス）

4. **JAPTトークンをMetaMaskに追加**
   - トークンコントラクトアドレス: （デプロイ後のJAPTアドレス）

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

## デプロイ手順（本番環境）

### 1. 環境変数を設定

`.env`ファイルを作成:
```bash
cp .env.example .env
```

`.env`を編集:
```
PRIVATE_KEY=あなたの秘密鍵
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
COMPANY_ADDRESS=会社のウォレットアドレス
SHOP_ADDRESS=ショップのウォレットアドレス
```

### 2. デプロイを実行

```bash
# Sepoliaテストネットにデプロイ
forge script script/DeployFullSystem.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# または、ローカル環境でテスト
anvil  # 別のターミナルで実行
forge script script/TestAutomation.s.sol --rpc-url http://localhost:8545 --broadcast
```

### 3. デプロイされたアドレスを確認

デプロイ後、コンソールに表示されるアドレスをメモ:
```
JPYD: 0x...
JAPoint: 0x...
JAPointMint: 0x...
JPYDWrapper: 0x...
Transfer10: 0x...
Transfer5: 0x...
```

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
