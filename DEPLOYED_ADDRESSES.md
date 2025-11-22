# 🚀 Sepoliaテストネット デプロイ済みアドレス

デプロイ日時: 2025-11-22

## 📋 コントラクトアドレス

| コントラクト | アドレス | Etherscanリンク |
|------------|---------|----------------|
| **JPYD** | `0xF60a976A2b9d21Bd19e63722fCdAc03C2737E9F9` | [View on Etherscan](https://sepolia.etherscan.io/address/0xf60a976a2b9d21bd19e63722fcdac03c2737e9f9) |
| **JAPoint (JAPT)** | `0x9C27a3f7a13b0D3aaE075Aa76b3dECB651e2BB36` | [View on Etherscan](https://sepolia.etherscan.io/address/0x9c27a3f7a13b0d3aae075aa76b3decb651e2bb36) |
| **JAPointMint** | `0x46a1A5e4fb2D7b859871f1A7d1d8E9b0B36Ae225` | [View on Etherscan](https://sepolia.etherscan.io/address/0x46a1a5e4fb2d7b859871f1a7d1d8e9b0b36ae225) |
| **JPYDWrapper** | `0x3C827F9fdf0E99f683074A86d4AD169043C29bd5` | [View on Etherscan](https://sepolia.etherscan.io/address/0x3c827f9fdf0e99f683074a86d4ad169043c29bd5) |
| **Transfer10** | `0xBA8eF1c9739AEd44a76B63e27A06a0dC56A36FC0` | [View on Etherscan](https://sepolia.etherscan.io/address/0xba8ef1c9739aed44a76b63e27a06a0dc56a36fc0) |
| **Transfer5** | `0x6b8c2bdD6E14bc45BA6358FC099DC74e9261bEd5` | [View on Etherscan](https://sepolia.etherscan.io/address/0x6b8c2bdd6e14bc45ba6358fc099dc74e9261bed5) |

## 🔧 設定情報

- **Company Address**: `0x79a1cE843bA4Aa4Bd833D91c925789f242Ea1F84`
- **Shop Address**: `0x7Abe610C0d12C261A281d4eDD8A68796fd044d90`
- **Initial JPYD Supply**: 10,000,000 JPYD
- **JAPoint Reserve**: 1,000,000,000,000 JAPT

## 📱 MetaMask設定

### トークンを追加

**JPYD トークン:**
- アドレス: `0xF60a976A2b9d21Bd19e63722fCdAc03C2737E9F9`
- シンボル: `JPYD`
- 小数点以下: `18`

**JAPT トークン:**
- アドレス: `0x9C27a3f7a13b0D3aaE075Aa76b3dECB651e2BB36`
- シンボル: `JAPT`
- 小数点以下: `18`

### ネットワーク設定

- **ネットワーク名**: Sepolia Test Network
- **Chain ID**: 11155111
- **通貨記号**: ETH

## 🌐 次のステップ: インターネット公開

HTMLファイルをGitHub Pagesにデプロイして、スマホからアクセス可能にします。

### 方法1: GitHub Web UI（簡単）

1. GitHubリポジトリを作成
2. 以下のファイルをアップロード:
   - `index.html`
   - `qr-codes-display.html`
   - `mobile-payment.html`
   - `frontend-example.html`
   - `qr-generator.html`
   - `DEPLOYED_ADDRESSES.md`
   - `MOBILE_ACCESS.md`
   - `MOBILE_PAYMENT_GUIDE.md`

3. Settings → Pages → Branch: main → Save

### 方法2: Git CLI

```bash
# gh-pagesブランチを作成
git checkout -b gh-pages

# HTMLファイルをコミット
git add *.html *.md
git commit -m "Deploy JAPOINT to Sepolia testnet"

# GitHubにプッシュ
git remote add origin https://github.com/YOUR_USERNAME/japoint-payment.git
git push -u origin gh-pages

# GitHub PagesをSettings → Pagesで有効化
```

公開URL: `https://YOUR_USERNAME.github.io/japoint-payment/`

## ✅ 完了確認

- [x] コントラクトをSepoliaにデプロイ
- [x] Etherscanで認証完了
- [x] HTMLファイルにアドレスを反映
- [ ] GitHub Pagesで公開
- [ ] スマホからアクセステスト

---

**注意**: これはSepoliaテストネットのデプロイです。本番環境（Ethereum Mainnet）ではありません。
