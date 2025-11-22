# 🚀 JAPOINT クイックスタート

## ✅ 現在の状況

- ✅ Webサーバー稼働中（ポート 8080）
- ✅ Anvil稼働中（ポート 8545）
- ✅ コントラクトデプロイ済み

---

## 📍 アクセスURL

### PCから:
```
http://localhost:8080
```

### スマホから（同じWi-Fi接続時）:
```
http://172.21.220.239:8080
```

---

## 📱 利用可能なページ

### 1. QRコード表示（メイン）
```
http://localhost:8080/qr-codes-display.html
```
- Transfer5（0.5%手数料）のQRコード
- Transfer10（1%手数料）のQRコード
- ダウンロード・印刷可能

### 2. PC版決済
```
http://localhost:8080/frontend-example.html
```
- デスクトップからの決済テスト
- コントラクトアドレスは自動設定済み

### 3. QRコードテスト
```
http://localhost:8080/test-qr.html
```
- QRライブラリの動作確認

---

## 🔧 トラブルシューティング

### QRコードが表示されない場合

1. **ブラウザのコンソールを確認**
   - F12キーでデベロッパーツールを開く
   - コンソールタブでエラーを確認

2. **ページを再読み込み**
   - Ctrl+Shift+R（ハードリロード）

3. **テストページで確認**
   ```
   http://localhost:8080/test-qr.html
   ```
   このページでQRコードが表示されれば、ライブラリは正常です

### PC版決済が動作しない場合

1. **MetaMaskをインストール**
   - https://metamask.io/

2. **ネットワークを追加**
   - ネットワーク名: Anvil Local
   - RPC URL: http://localhost:8545
   - Chain ID: 31337

3. **テストアカウントをインポート**
   ```
   秘密鍵: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```

4. **ページにアクセス**
   ```
   http://localhost:8080/frontend-example.html
   ```
   コントラクトアドレスは自動設定されています

---

## 📱 スマホでテストする手順

### 1. MetaMask Mobileをインストール

### 2. ネットワーク設定
- ネットワーク名: `Anvil Local`
- RPC URL: `http://172.21.220.239:8545`
- Chain ID: `31337`
- 通貨: `ETH`

### 3. テストアカウントをインポート
```
秘密鍵: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
```

### 4. トークンを追加
- JPYD: `0x0355B7B8cb128fA5692729Ab3AAa199C1753f726`
- JAPT: `0x202CCe504e04bEd6fC0521238dDf04Bc9E8E15aB`

### 5. QRコードをスキャン
```
http://172.21.220.239:8080/qr-codes-display.html
```

---

## 🔄 サーバー管理

### サーバー確認
```bash
ps aux | grep "python3 -m http.server"
```

### サーバー停止
```bash
ps aux | grep "python3 -m http.server" | grep -v grep | awk '{print $2}' | xargs kill
```

### サーバー再起動
```bash
cd /home/kenichiuejo/src/JAPOINT
python3 -m http.server 8080 --bind 0.0.0.0 &
```

---

## 📊 デプロイ済みコントラクト（Anvil Local）

| コントラクト | アドレス |
|------------|---------|
| JPYD | 0x0355B7B8cb128fA5692729Ab3AAa199C1753f726 |
| JPYDWrapper | 0x172076E0166D1F9Cc711C77Adf8488051744980C |
| Transfer10 | 0x4EE6eCAD1c2Dae9f525404De8555724e3c35d07B |
| Transfer5 | 0xBEc49fA140aCaA83533fB00A2BB19bDdd0290f25 |
| JAPoint | 0x202CCe504e04bEd6fC0521238dDf04Bc9E8E15aB |

---

## ✅ 動作確認チェックリスト

- [ ] http://localhost:8080 にアクセスできる
- [ ] QRコード表示ページでQRコードが表示される
- [ ] PC版決済ページでMetaMaskに接続できる
- [ ] 残高が表示される
- [ ] テスト決済が成功する

---

## 💡 次のステップ

1. **今すぐアクセス**: http://localhost:8080
2. **QRコードを確認**: 「QRコード表示」をクリック
3. **PC版決済をテスト**: 「PC版決済」をクリック
4. **スマホでテスト**: QRコードをスキャン

---

## 🆘 よくある質問

### Q: サーバーのIPアドレスが違う場合は？
A: 以下のコマンドで確認できます:
```bash
hostname -I | awk '{print $1}'
```

### Q: Anvilが停止している場合は？
A: 新しいターミナルで起動:
```bash
anvil
```

### Q: コントラクトを再デプロイしたい場合は？
A: Anvilを再起動してから:
```bash
forge script script/TestAutomation.s.sol --rpc-url http://localhost:8545 --broadcast
```

---

すべて準備完了です！🎉
今すぐ http://localhost:8080 にアクセスしてください！
