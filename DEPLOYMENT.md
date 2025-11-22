# JAPOINT デプロイメント情報

## 🌐 Sepoliaテストネット デプロイメント

**デプロイ日**: 2025-11-22
**ネットワーク**: Sepolia Testnet
**Chain ID**: 11155111

---

## 📝 コントラクトアドレス

| コントラクト | アドレス | 説明 |
|------------|---------|------|
| **JPYD** | `0xdD870D138DC6081E664c5127226e815cc4C6f87D` | JPY-ペッグステーブルコイン |
| **JAPoint** | `0x2eDf302548B23e9F599e483aE79cda6D8774c6fC` | JAPTリワードトークン |
| **JAPointMint** | `0x24FC91c3895042ABaCD0245eC8edD521BB8a29da` | JAPT配布コントラクト |
| **JPYDWrapper** | `0xa30042F978913cE9B466e204E7F729AeBCb3c624` | 自動通知機能ラッパー（修正版） |
| **Transfer10** | `0xA3963E928B35Ac06cC519b2a1BbBc3F27aCf0460` | 1%手数料決済コントラクト |
| **Transfer5** | `0x74F6CfD89751a677E74130752483a530e27D4819` | 0.5%手数料決済コントラクト |

### 運営アドレス

| 役割 | アドレス |
|-----|---------|
| **Company Address** | `0x79a1cE843bA4Aa4Bd833D91c925789f242Ea1F84` |
| **Shop Address** | `0x7Abe610C0d12C261A281d4eDD8A68796fd044d90` |

---

## 🔗 決済URL

### Transfer10（1%手数料）

```
https://kkuejo.github.io/japoint-payment/mobile-payment.html?shop=テストショップ（1%）&type=transfer10&jpyd=0xdD870D138DC6081E664c5127226e815cc4C6f87D&wrapper=0xa30042F978913cE9B466e204E7F729AeBCb3c624&target=0xA3963E928B35Ac06cC519b2a1BbBc3F27aCf0460&japt=0x2eDf302548B23e9F599e483aE79cda6D8774c6fC
```

### Transfer5（0.5%手数料）

```
https://kkuejo.github.io/japoint-payment/mobile-payment.html?shop=テストショップ（0.5%）&type=transfer5&jpyd=0xdD870D138DC6081E664c5127226e815cc4C6f87D&wrapper=0xa30042F978913cE9B466e204E7F729AeBCb3c624&target=0x74F6CfD89751a677E74130752483a530e27D4819&japt=0x2eDf302548B23e9F599e483aE79cda6D8774c6fC
```

---

## 🔧 重要な変更点

### JPYDWrapper.sol の修正

このデプロイメントでは、以前のバージョンで発生した問題を修正しました：

**問題**:
- `onTokenReceived`が失敗してもトランザクションは成功していた
- トークンがTransfer10に残留し、第三者による横取りが可能だった

**修正内容**:
- `_notifyTokenReceived`関数で、callが失敗した場合にrequireでrevertするように変更
- エラーメッセージを抽出して、詳細なエラー情報を提供
- これにより、`onTokenReceived`が失敗した場合、トランザクション全体が失敗し、トークンはユーザーの手元に残る

**コード変更箇所**: `src/JPYDWrapper.sol:94-128`

---

## 📊 初期設定

| 項目 | 値 |
|-----|-----|
| **JPYD 初期供給量** | 10,000,000 JPYD |
| **JAPT リザーブ** | 1,000,000,000,000 JAPT (1兆) |
| **Transfer10 手数料率** | 1% |
| **Transfer5 手数料率** | 0.5% |

---

## 🧪 テスト方法

### 1. MetaMask設定

#### Sepoliaネットワークを追加
- **ネットワーク名**: Sepolia Test Network
- **RPC URL**: `https://ethereum-sepolia-rpc.publicnode.com`
- **Chain ID**: `11155111`
- **通貨記号**: ETH
- **Block Explorer**: `https://sepolia.etherscan.io`

### 2. テストETHの取得

Sepolia Faucetからテストネット用のETHを取得:
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia

### 3. JPYDトークンの取得

JPYDトークンをMetaMaskに追加:
- **トークンアドレス**: `0xdD870D138DC6081E664c5127226e815cc4C6f87D`
- **トークンシンボル**: JPYD
- **小数点**: 18

### 4. 決済テスト

1. 上記の決済URLをモバイルのMetaMask Mobileブラウザで開く
2. 「MetaMaskで接続」ボタンをタップ
3. 金額を入力（例: 1000 JPYD）
4. 「支払う」ボタンをタップ
5. MetaMaskで署名を承認
6. トランザクション完了を待つ
7. JAPTトークンが自動的に付与されることを確認

---

## 📱 QRコードの使用

QRコード表示ページ:
```
https://kkuejo.github.io/japoint-payment/qr-codes-display.html
```

このページでは:
- Transfer10とTransfer5のQRコードを表示
- QRコードのダウンロード（PNG形式）
- 決済URLの確認とコピー

---

## ⚠️ セキュリティ注意事項

1. **テストネット専用**: このデプロイメントはSepoliaテストネット専用です。実際の価値を持つトークンではありません。
2. **秘密鍵の管理**: 秘密鍵を安全に保管し、公開しないでください。
3. **コントラクトの検証**: すべてのコントラクトはSolidityで記述され、Foundryでテスト済みです。
4. **監査状況**: このコントラクトは外部監査を受けていません。テスト目的でのみ使用してください。

---

## 🛠️ トラブルシューティング

### トランザクションが失敗する

**症状**: 決済時にトランザクションが失敗する

**原因と対処法**:
1. **ガス不足**: Sepoliaテストネット用のETHが不足している
   - 対処: Faucetから追加のETHを取得
2. **JPYD残高不足**: JPYDトークンの残高が不足している
   - 対処: JPYDトークンを取得するか、金額を減らす
3. **ネットワーク接続**: MetaMaskがSepoliaネットワークに接続されていない
   - 対処: MetaMaskでSepoliaネットワークが選択されているか確認

### JAPTが受け取れない

**症状**: 決済は成功したが、JAPTが付与されない

**原因**: これは修正済みの問題です。新しいデプロイメントでは、決済が成功した場合は必ずJAPTが付与されます。

**確認方法**:
1. MetaMaskでJAPTトークンを追加
   - トークンアドレス: `0x2eDf302548B23e9F599e483aE79cda6D8774c6fC`
2. Sepolia Etherscanでトランザクションを確認
   - `PaymentProcessed`イベントが発行されているか確認

---

## 📚 関連リンク

- **GitHub Pages**: https://kkuejo.github.io/japoint-payment/
- **Sepolia Etherscan**: https://sepolia.etherscan.io/
- **Foundry Documentation**: https://book.getfoundry.sh/

---

## 📞 サポート

問題が発生した場合は、GitHubのIssuesでご報告ください。

---

**最終更新**: 2025-11-22
