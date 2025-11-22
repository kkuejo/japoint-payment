# JAPOINT System

JPYD（日本円ペッグステーブルコイン）、JAPoint報酬、ガス最適化アーキテクチャを備えた自動決済処理機能を持つ、SolidityとFoundryで構築された完全なステーブルコイン決済・報酬システムです。

## システム概要

このプロジェクトは、自動報酬配布によるシームレスな決済処理を提供するために連携する5つの主要なコントラクトで構成されています。

### 1. JPYD (JPY Digital)
- JPYC仕様に準拠した日本円ペッグステーブルコイン
- 18桁の小数点を持つERC20準拠トークン
- ミント可能・バーン可能
- EIP-2612 permit機能
- **自動通知システム**: サポートされたコントラクトにトークンが送信されると、自動的に決済処理をトリガー

### 2. JAPoint (JA Point)
- 18桁の小数点を持つERC20報酬トークン（シンボル: JAPT）
- オーナーによるミント可能（初期デプロイ時はコントラクトオーナー）
- トークンホルダーによるバーン可能
- 決済取引を通じて獲得可能

### 3. JAPointMint
- **ガス最適化された配布コントラクト**（事前ミント済みトークンリザーブを使用）
- 配布用リザーブとして1兆JAPT（1,000,000,000,000）を保持
- ユーザーがJPYDを承認し、`transferJAPoint(recipient)`を呼び出してJAPointを受け取る
- JPYDは指定された会社アドレスに転送される
- 1:1の交換レート（1 JPYD = 1 JAPT）
- **取引ごとのミント不要** - ガスコストを大幅に削減

### 4. Transfer10
- 自動報酬機能付き決済処理コントラクト
- **3つの決済処理方法**:
  1. **自動**: MetaMask転送でJPYDを直接送信するだけ（ガスリミット: 500,000+）
  2. **deposit(amount)**: 処理する正確な金額を指定
  3. **processPayment()**: 承認済みのすべてのJPYDを処理
- JPYD決済を受け取り、配布する:
  - 1%をJAPointMintに（ユーザーは同等のJAPointを報酬として受け取る）
  - 99%をショップアドレスに（マーチャントへの決済）
- 1トランザクションで決済+報酬プロセスを簡素化

### 5. Transfer5
- Transfer10と同様の自動報酬機能付き決済処理コントラクト
- **Transfer10との違い**: 報酬配分が異なる
- **3つの決済処理方法**:
  1. **自動**: MetaMask転送でJPYDを直接送信するだけ（ガスリミット: 500,000+）
  2. **deposit(amount)**: 処理する正確な金額を指定
  3. **processPayment()**: 承認済みのすべてのJPYDを処理
- JPYD決済を受け取り、配布する:
  - 0.5%をJAPointMintに（ユーザーは同等のJAPointを報酬として受け取る）
  - 99.5%をショップアドレスに（マーチャントへの決済）
- Transfer10よりも低い報酬率で、より多くの金額をショップに配布

## 主な機能

### 自動決済処理
MetaMaskやウォレットからTransfer10アドレスにJPYDを直接送信 - **関数呼び出し不要**！
- JPYDが受信者がTransfer10コントラクトであることを検出
- 自動的に`onTokenReceived()`を呼び出し
- 同じトランザクション内で決済配布を処理
- **ガス要件**: 約186,728ガス（安全のためガスリミットを500,000に設定）

### ガス最適化アーキテクチャ
- 取引ごとのミントではなく、**転送ベースの配布**
- **事前ミント済みリザーブ**: デプロイ時にJAPointMintに1兆JAPTをミント
- ミント毎取引アプローチと比較してガスコストを約2.2%削減
- より安全: JAPointMintはJAPointのオーナーである必要がない

## 動作方法

### 方法1: 自動決済処理（推奨）

**Transfer10アドレスにJPYDを送信するだけ！**

```bash
# castを使用（ガスリミットを500,000に設定）
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  500000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**自動的に発生すること:**
1. JPYD転送が完了
2. JPYDがTransfer10がコントラクトであることを検出
3. 自動的に`Transfer10.onTokenReceived()`を呼び出し
4. Transfer10が決済を処理:
   - 1%をJAPointMintに承認
   - `transferJAPoint(sender)`を呼び出し - 送信者がJAPT報酬を受け取る
   - 99%をショップに転送
   - `PaymentProcessed`イベントを発行
5. すべてが1トランザクションで完了！

### 方法2: deposit()による手動処理

```bash
# 1. Transfer10にJPYDを承認
cast send <JPYD_ADDRESS> \
  "approve(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# 2. 特定の金額をデポジット
cast send <TRANSFER10_ADDRESS> \
  "deposit(uint256)" \
  5000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 方法3: Transfer5を使用した自動決済処理（0.5%報酬）

Transfer5はTransfer10と同様に動作しますが、報酬率が0.5%です:

```bash
# castを使用（ガスリミットを500,000に設定）
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER5_ADDRESS> \
  500000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**自動的に発生すること:**
1. JPYD転送が完了
2. JPYDがTransfer5がコントラクトであることを検出
3. 自動的に`Transfer5.onTokenReceived()`を呼び出し
4. Transfer5が決済を処理:
   - 0.5%をJAPointMintに承認
   - `transferJAPoint(sender)`を呼び出し - 送信者がJAPT報酬を受け取る
   - 99.5%をショップに転送
   - `PaymentProcessed`イベントを発行
5. すべてが1トランザクションで完了！

### 方法4: 直接JAPoint交換

JAPointMint経由でJPYDをJAPointに直接交換:

```bash
# 1. JAPointMintにJPYDを承認
cast send <JPYD_ADDRESS> \
  "approve(address,uint256)" \
  <JAPOINTMINT_ADDRESS> \
  1000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# 2. JAPointを転送（JPYDは会社に転送される）
cast send <JAPOINTMINT_ADDRESS> \
  "transferJAPoint(address)" \
  <RECIPIENT_ADDRESS> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## コントラクト詳細

| コントラクト | 名前 | シンボル | 小数点 | 機能 |
|----------|------|--------|----------|----------|
| JPYD | JPY Digital | JPYD | 18 | ミント可能、バーン可能、Permit、自動通知 |
| JAPoint | JA Point | JAPT | 18 | ミント可能（オーナーのみ）、バーン可能 |
| JAPointMint | - | - | - | 事前ミント済みリザーブ（1T JAPT）、1:1交換、会社への転送 |
| Transfer10 | - | - | - | 自動処理、1%報酬、99%をショップへ |
| Transfer5 | - | - | - | 自動処理、0.5%報酬、99.5%をショップへ |

すべてのコントラクトはOpenZeppelin Contracts v5.5.0に基づいており、Solidity ^0.8.20を使用しています。

## 前提条件

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.20
- Sepoliaデプロイ用のテストネットETHを持つEthereumウォレット、またはローカルテスト用のAnvil
- RPCエンドポイント（Alchemy、Infuraなど）

## インストール

```bash
# リポジトリをクローン
git clone <your-repo-url>
cd JAPOINT

# 依存関係をインストール（OpenZeppelin Contractsとforge-std）
forge install
```

依存関係:
- OpenZeppelin Contracts v5.5.0
- forge-std v1.11.0

## ビルド

```bash
forge build
```

## テスト

すべてのテストを実行:
```bash
forge test
```

詳細出力でテストを実行:
```bash
forge test -vv
```

ガスレポート付きでテストを実行:
```bash
forge test --gas-report
```

特定のテストコントラクトを実行:
```bash
forge test --match-contract Transfer10Test -vv
```

特定のテスト関数を実行:
```bash
forge test --match-test testAutomaticProcessingViaTransfer -vv
```

テストカバレッジには以下が含まれます:
- すべてのコントラクトのユニットテスト
- 決済フローの統合テスト
- エッジケースのファズテスト
- 自動処理テスト

## Anvilを使用したローカル開発

### 1. Anvilを起動

```bash
anvil
```

### 2. 完全なシステムをデプロイ

```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
COMPANY_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
SHOP_ADDRESS=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC \
forge script script/DeployFullSystem.s.sol:DeployFullSystem \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

これにより以下がデプロイされます:
- 初期供給量10MのJPYD
- JAPoint
- 1兆JAPTリザーブ付きのJAPointMint
- 決済処理用のTransfer10（1%報酬）
- 決済処理用のTransfer5（0.5%報酬）

### 3. 自動処理をテスト

```bash
# Transfer10にJPYDを直接送信（自動処理）
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  500000000000000000000 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --rpc-url http://127.0.0.1:8545 \
  --gas-limit 500000
```

## 🌐 Sepoliaテストネットデプロイメント

### 現在のデプロイ済みコントラクト（2025-11-22）

JAPOINTシステムはSepoliaテストネットで稼働中です：

| コントラクト | アドレス | Etherscan |
|------------|---------|-----------|
| **JPYD** | `0xdD870D138DC6081E664c5127226e815cc4C6f87D` | [View](https://sepolia.etherscan.io/address/0xdD870D138DC6081E664c5127226e815cc4C6f87D) |
| **JAPoint** | `0x2eDf302548B23e9F599e483aE79cda6D8774c6fC` | [View](https://sepolia.etherscan.io/address/0x2eDf302548B23e9F599e483aE79cda6D8774c6fC) |
| **JAPointMint** | `0x24FC91c3895042ABaCD0245eC8edD521BB8a29da` | [View](https://sepolia.etherscan.io/address/0x24FC91c3895042ABaCD0245eC8edD521BB8a29da) |
| **JPYDWrapper** | `0xa30042F978913cE9B466e204E7F729AeBCb3c624` | [View](https://sepolia.etherscan.io/address/0xa30042F978913cE9B466e204E7F729AeBCb3c624) |
| **Transfer10** | `0xA3963E928B35Ac06cC519b2a1BbBc3F27aCf0460` | [View](https://sepolia.etherscan.io/address/0xA3963E928B35Ac06cC519b2a1BbBc3F27aCf0460) |
| **Transfer5** | `0x74F6CfD89751a677E74130752483a530e27D4819` | [View](https://sepolia.etherscan.io/address/0x74F6CfD89751a677E74130752483a530e27D4819) |

**モバイル決済URL**: https://kkuejo.github.io/japoint-payment/

詳細情報: [DEPLOYMENT.md](DEPLOYMENT.md) | [セットアップ手順](SETUP_INSTRUCTIONS.md) | [使用ガイド](USAGE_GUIDE.md)

### 新しくデプロイする場合

#### 1. 環境変数の設定

```bash
export PRIVATE_KEY=your_private_key_here
export COMPANY_ADDRESS=your_company_address_here
export SHOP_ADDRESS=your_shop_address_here
```

または、`.env`ファイルを作成（`.gitignore`に追加済み）。

#### 2. Sepolia ETHを取得

Faucet: https://sepoliafaucet.com/

#### 3. デプロイ実行

```bash
source .env

forge script script/DeployFullSystem.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --slow \
  --legacy
```

## 使用例

### 自動処理（最も簡単な方法）

**例**: Transfer10経由でショップに10,000 JPYDを支払う

```bash
# JPYDを直接送信するだけ - すべてが自動的に処理されます！
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**結果:**
- 自動的に受け取る: 100 JAPT（1%報酬）
- ショップが受け取る: 9,900 JPYD（99%決済）
- 会社が受け取る: 100 JPYD（JAPointMintから）
- すべてが1トランザクションで完了！

**重要**: 自動処理のためにはガスリミットを500,000以上に設定してください

### Transfer5を使用した自動処理（0.5%報酬）

**例**: Transfer5経由でショップに10,000 JPYDを支払う

```bash
# JPYDを直接送信するだけ - すべてが自動的に処理されます！
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER5_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**結果:**
- 自動的に受け取る: 50 JAPT（0.5%報酬）
- ショップが受け取る: 9,950 JPYD（99.5%決済）
- 会社が受け取る: 50 JPYD（JAPointMintから）
- すべてが1トランザクションで完了！

**重要**: 自動処理のためにはガスリミットを500,000以上に設定してください

### deposit()による手動処理

```bash
# 1. Transfer10にJPYDを承認
cast send <JPYD_ADDRESS> \
  "approve(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# 2. 特定の金額で決済を処理
cast send <TRANSFER10_ADDRESS> \
  "deposit(uint256)" \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### Transfer5を使用した自動処理（0.5%報酬）

**例**: Transfer5経由でショップに10,000 JPYDを支払う

```bash
# JPYDを直接送信するだけ - すべてが自動的に処理されます！
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER5_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**結果:**
- 自動的に受け取る: 50 JAPT（0.5%報酬）
- ショップが受け取る: 9,950（99.5%決済）
- 会社が受け取る: 50 JPYD（JAPointMintから）
- すべてが1トランザクションで完了！

**重要**: 自動処理のためにはガスリミットを500,000以上に設定してください

### 直接JAPoint交換

JPYDをJAPTに直接交換:

```bash
# 1. JAPointMintにJPYDを承認
cast send <JPYD_ADDRESS> \
  "approve(address,uint256)" \
  <JAPOINTMINT_ADDRESS> \
  1000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# 2. JAPointを取得（JPYDは会社に送られる）
cast send <JAPOINTMINT_ADDRESS> \
  "transferJAPoint(address)" \
  <RECIPIENT_ADDRESS> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 残高確認

JPYD残高を確認:
```bash
cast call <JPYD_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <WALLET_ADDRESS> \
  --rpc-url $RPC_URL
```

JAPoint残高を確認:
```bash
cast call <JAPOINT_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <WALLET_ADDRESS> \
  --rpc-url $RPC_URL
```

JAPointMintリザーブを確認:
```bash
cast call <JAPOINT_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <JAPOINTMINT_ADDRESS> \
  --rpc-url $RPC_URL
```

### 管理機能

会社アドレスを更新（JAPointMintオーナーのみ）:
```bash
cast send <JAPOINTMINT_ADDRESS> \
  "updateCompanyAddress(address)" \
  <NEW_COMPANY_ADDRESS> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

ショップアドレスを更新（Transfer10オーナーのみ）:
```bash
cast send <TRANSFER10_ADDRESS> \
  "updateShopAddress(address)" \
  <NEW_SHOP_ADDRESS> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## コントラクト間の相互作用

### 自動決済フロー（transfer経由）

```
User                 JPYD                Transfer10          JAPointMint         JAPoint        Company/Shop
  |                    |                      |                   |                 |                |
  |--transfer(T10)---->|                      |                   |                 |                |
  |  (500 JPYD)        |                      |                   |                 |                |
  |                    |                      |                   |                 |                |
  |                    |--transfer----------->|                   |                 |                |
  |                    |(500 JPYD)            |                   |                 |                |
  |                    |                      |                   |                 |                |
  |                    |                      |--_isContract()    |                 |                |
  |                    |                      |  (yes)            |                 |                |
  |                    |                      |                   |                 |                |
  |                    |                      |--onTokenReceived()|                 |                |
  |                    |<--call---------------|                   |                 |                |
  |                    |                      |                   |                 |                |
  |                    |                      |--approve(5)------>|                 |                |
  |                    |                      |                   |                 |                |
  |                    |                      |--transferJAPoint->|                 |                |
  |                    |                      |  (sender)         |                 |                |
  |                    |                      |                   |                 |                |
  |                    |                      |                   |--transferFrom->|                 |
  |                    |<--JPYD(5)------------|                   |(from T10)      |                |
  |                    |                      |                   |                |                |
  |                    |                      |                   |--transfer----->|                |
  |<--JAPT(5)------------------------------------------(reward)---|                |                |
  |                    |                      |                   |                |                |
  |                    |                      |                   |--transfer JPYD(5)----------->|  |
  |                    |                      |                   |                |          (Company)
  |                    |                      |                   |                |                |
  |                    |                      |--transfer JPYD(495)-------------------------------->|
  |                    |                      |                   |                |           (Shop)
  |                    |<--return true--------|                   |                |                |
  |                    |                      |                   |                |                |
  |                    |--emit NotificationAttempt(T10, true)     |                |                |
  |<--return true------|                      |                   |                |                |
```

### 手動決済フロー（deposit経由）

```
User                  Transfer10            JAPointMint         JAPoint        Company/Shop
  |                        |                     |               |                |
  |--approve JPYD--------->|                     |               |                |
  |                        |                     |               |                |
  |--deposit(500)--------->|                     |               |                |
  |                        |                     |               |                |
  |                        |--transferFrom-------|               |                |
  |                        |(500 JPYD from user) |               |                |
  |                        |                     |               |                |
  |                        |--approve(5)-------->|               |                |
  |                        |                     |               |                |
  |                        |--transferJAPoint--->|               |                |
  |                        |  (sender)           |               |                |
  |                        |                     |               |                |
  |                        |                     |--transferFrom>|                |
  |                        |                     |(5 JAPT from   |                |
  |                        |                     | reserve)      |                |
  |<----JAPT reward (5)-------------------------|               |                |
  |                        |                     |               |                |
  |                        |                     |--transfer JPYD(5)------------>|
  |                        |                     |               |          (Company)
  |                        |                     |               |                |
  |                        |--transfer JPYD(495)-------------------------------->|
  |                        |                     |               |           (Shop)
```

## ガスコスト

| 操作 | ガスコスト | 備考 |
|-----------|----------|-------|
| 自動処理（transfer） | ~186,728 | ガスリミットを500,000+に設定 |
| 手動deposit() | ~155,000 | 概算 |
| 直接transferJAPoint() | ~120,000 | 概算 |

転送ベースアーキテクチャによるガス節約: ミント毎取引と比較して**約2.2%**削減。

## セキュリティ考慮事項

- **事前ミント済みリザーブ**: JAPointMintは1兆JAPTを保持 - 予想される使用量に対して十分なリザーブを確保
- **承認が必要**: ユーザーは`deposit()`、`processPayment()`、または`transferJAPoint()`メソッドを使用する前にJPYDを承認する必要がある
- **自動転送**: Transfer10またはTransfer5への直接`transfer()`は承認不要だが、ガスリミット500,000+が必要
- **自動処理のガスリミット**: transfer経由の自動処理にはガスリミットを500,000+に設定する必要がある
- **アドレス管理**: 会社とショップのアドレスはコントラクトオーナーによって更新可能
- **トークン回復**: 誤って送信されたトークンを回復するための緊急機能（`recoverTokens()`）が利用可能（自動処理される`transfer()`経由で送信されたJPYDを除く）
- **秘密鍵**: 秘密鍵をバージョン管理にコミットしないこと
- **テスト**: すべてのコントラクトにはファズテストを含む包括的なテストカバレッジがある
- **ITokenReceiverインターフェース**: Transfer10とTransfer5がこれを実装 - 不正な自動処理を防止
- **Transfer vs TransferFrom**: 直接`transfer()`のみが自動処理をトリガー; コントラクトで使用される`transferFrom()`は通知をトリガーしない

## 技術詳細

### 自動処理の実装

JPYDコントラクト:
- `transfer()`をオーバーライドして受信者がコントラクトかどうかをチェック
- `onTokenReceived()`セレクターで低レベル`call()`を呼び出し
- 低レベル呼び出しを使用して利用可能なすべてのガスを転送（ガスリミット指定なし）
- 成功/失敗を追跡するために`NotificationAttempt`イベントを発行
- `transfer()`のみが自動処理をトリガー; `transferFrom()`はトリガーしない

Transfer10コントラクト:
- `ITokenReceiver`インターフェースを実装
- `onTokenReceived()`が呼び出し元がJPYDコントラクトであることを検証
- 同じトランザクション内で決済配布を処理
- 追跡のためのイベントを発行

### JAPointMintリザーブシステム

- デプロイ時にJAPointMintに1兆JAPTをミント
- 取引ごとの`mint()`ではなく`transfer()`を使用
- ガス節約: 所有権の転送やミント権限が不要
- より安全: JAPointMintはJAPointのオーナーである必要がない
- リザーブは`balanceOf(JAPointMint)`で監視可能

## 開発

コードをフォーマット:
```bash
forge fmt
```

ガススナップショットを生成:
```bash
forge snapshot
```

ビルド成果物をクリーン:
```bash
forge clean
```

## プロジェクト構造

```
.
├── src/
│   ├── JPYD.sol              # 標準ERC20準拠JPYペッグステーブルコイン（mint、decimalsのみ追加）
│   ├── JPYDWrapper.sol       # JPYD/JPYC用自動通知機能ラッパー
│   ├── JAPoint.sol           # JA Point報酬トークン
│   ├── JAPointMint.sol       # 転送ベースのJPYD→JAPoint交換
│   ├── Transfer10.sol        # 自動報酬機能付き決済処理（1%報酬）
│   ├── Transfer5.sol         # 自動報酬機能付き決済処理（0.5%報酬）
│   ├── ITokenReceiver.sol    # 自動通知用インターフェース
├── test/
│   ├── JPYD.t.sol            # JPYDテスト
│   ├── JAPointMint.t.sol     # JAPointとJAPointMintテスト
│   └── Transfer10.t.sol      # Transfer10テスト（自動処理を含む）
├── script/
│   └── DeployFullSystem.s.sol        # 1T JAPTリザーブ付き全コントラクト（JPYD、JAPoint、JAPointMint、JPYDWrapper、Transfer10、Transfer5）
├── foundry.toml              # Foundry設定
└── README.md
```

## 使用ケース

### シナリオ1: MetaMask経由の簡単な決済（推奨）
1. 顧客がMetaMaskを開く
2. Transfer10コントラクトアドレスに10,000 JPYDを送信
3. **すべてが1トランザクションで自動的に処理されます:**
   - ショップが9,900 JPYDを受け取る（99%）
   - 顧客が100 JAPTを受け取る（1%報酬）
   - 会社が100 JPYDを受け取る
4. 顧客はウォレットでJAPT報酬をすぐに確認できる

### シナリオ2: Eコマース統合
1. Eコマースサイトが決済先としてTransfer10アドレスを表示
2. 顧客が任意のウォレットからJPYDを送信（ガスリミット500,000+）
3. バックエンドが`PaymentProcessed`イベントを監視
4. イベント検出時に注文が自動的に確認される
5. 顧客が自動的にロイヤリティポイント（JAPT）を獲得

### シナリオ3: 直接JAPoint購入
1. ユーザーがJPYDでJAPointを購入したい
2. ユーザーが承認して`transferJAPoint()`を呼び出し
3. ユーザーが事前ミント済みリザーブからJAPTを受け取る
4. 会社がJPYDを受け取る
5. 新しいトークンはミントされない（ガス効率的）

### シナリオ4: 複数の決済で報酬を蓄積
1. 顧客がTransfer10経由で複数の購入を行う
2. 各購入で自動的に1%のJAPT報酬を獲得
3. 報酬が顧客のウォレットに蓄積される
4. 顧客が蓄積されたJAPTを取引または使用可能

## 比較: 最適化前と最適化後

| 機能 | 最適化前（Mint） | 最適化後（Transfer） |
|---------|--------------|------------------|
| JAPoint配布 | 取引ごとにミント | リザーブから転送 |
| ガスコスト | ~190,924 | ~186,728 (-2.2%) |
| JAPointMint所有権 | JAPointを所有する必要がある | 所有権不要 |
| リザーブ | N/A | 1兆JAPT |
| 関数名 | `mint()` | `transferJAPoint()` |
| セキュリティ | オーナーが制御 | よりシンプルで安全 |

## トラブルシューティング

### 自動処理での「Out of Gas」エラー
- **解決策**: ガスリミットを500,000以上に増やす
- 自動処理はネストされたコントラクト呼び出しにより、より多くのガスを必要とします

### 「Only JPYD tokens accepted」エラー
- **解決策**: Transfer10にはJPYDトークンのみを送信し、他のトークンは送信しない
- Transfer10は自動処理のためにJPYDのみを受け付けます

### 「Insufficient JAPoint reserve」エラー
- **解決策**: JAPointMintリザーブが枯渇しているため、より多くのJAPTを追加する必要がある
- リザーブを確認: `cast call <JAPOINT> "balanceOf(address)" <JAPOINTMINT>`

### 自動処理がトリガーされない
- **解決策**: `transferFrom()`ではなく`transfer()`を使用していることを確認
- 直接`transfer()`のみが自動処理をトリガーします
- `transferFrom()`はコントラクトで使用され、通知をトリガーしません

## ライセンス

MIT

## Foundryドキュメント

Foundryの詳細情報:
- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Documentation](https://book.getfoundry.sh/forge/)
- [Cast Documentation](https://book.getfoundry.sh/cast/)
