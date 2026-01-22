# JAPOINT Payment System

A complete stablecoin payment and reward system built with Solidity and Foundry. Customers pay with JPYC (Japanese Yen stablecoin) and receive JAPT (JAPoint) tokens as rewards.

## Live Demo

- **Payment System**: https://japoint-payment.pages.dev
- **API**: https://japoint-api.kkuejo.workers.dev

## System Architecture

```
Frontend (Cloudflare Pages)          Backend (Cloudflare Workers)
┌─────────────────────────┐          ┌─────────────────────────┐
│  index.html (Shop)      │          │  Workers API            │
│  mobile-payment.html    │◄────────►│  - POST /api/payments   │
│  dashboard.html         │          │  - GET /api/payments    │
│  add-japt.html          │          │  - GET /api/summary     │
└───────────┬─────────────┘          └───────────┬─────────────┘
            │                                    │
            ▼                                    ▼
┌─────────────────────────┐          ┌─────────────────────────┐
│  MetaMask Mobile        │          │  Cloudflare D1          │
│  (User Wallet)          │          │  (SQLite Database)      │
└───────────┬─────────────┘          └─────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Ethereum Sepolia Testnet                  │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   JPYC   │◄─│ JPYCWrapper  │─►│ Transfer10/Transfer5 │   │
│  └──────────┘  └──────────────┘  └──────────┬───────────┘   │
│                                              │               │
│                                              ▼               │
│                                  ┌──────────────────────┐   │
│                                  │     JAPointMint      │   │
│                                  │  ┌────────────────┐  │   │
│                                  │  │   JAPT Token   │  │   │
│                                  │  └────────────────┘  │   │
│                                  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| HTML/CSS/JavaScript | User Interface |
| ethers.js | Ethereum integration (v5.7.2 mobile, v6.9.0 desktop) |
| QRCode.js | QR code generation |
| Cloudflare Pages | Hosting |

### Backend API
| Technology | Purpose |
|------------|---------|
| Cloudflare Workers | Serverless API |
| Cloudflare D1 | SQLite database |
| Wrangler | Deployment tool |

### Smart Contracts
| Technology | Purpose |
|------------|---------|
| Solidity ^0.8.20 | Contract language |
| OpenZeppelin | Security library |
| Foundry | Development & testing |

### Network
| Item | Value |
|------|-------|
| Chain | Ethereum Sepolia Testnet |
| Chain ID | 11155111 |

## Smart Contracts

### Contract Overview

| Contract | Purpose | Fee |
|----------|---------|-----|
| JPYC | Japanese Yen stablecoin (existing) | - |
| JAPT (JAPoint) | Reward token (ERC20) | - |
| JPYCWrapper | Adds notification to JPYC transfers | - |
| Transfer10 | Payment processor | 1% |
| Transfer5 | Payment processor | 0.5% |
| JAPointMint | Distributes JAPT rewards | - |

### Deployed Addresses (Sepolia)

| Contract | Address |
|----------|---------|
| JAPT | `0xE477E1789F928facAA0f2513bA0d18345c97123D` |

Other contract addresses are configured via URL parameters.

## Payment Flow

1. Customer scans QR code with MetaMask Mobile
2. Opens mobile-payment.html with contract addresses in URL
3. Customer enters amount and taps "Pay"
4. JPYC approve transaction (MetaMask confirmation)
5. JPYCWrapper.transfer() executes:
   - 1%/0.5% fee → JAPointMint → JAPT sent to customer
   - 99%/99.5% → Shop address
6. Payment recorded to D1 database via API

## Frontend Pages

| File | Purpose |
|------|---------|
| `index.html` | Shop dashboard (QR generation, notifications) |
| `mobile-payment.html` | Customer payment page (mobile) |
| `dashboard.html` | Admin dashboard (payment history, stats) |
| `add-japt.html` | Add JAPT token to MetaMask |

## API Endpoints

Base URL: `https://japoint-api.kkuejo.workers.dev`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/payments` | Record payment |
| GET | `/api/payments` | Get payment history |
| GET | `/api/payments/summary` | Get summary stats |
| GET | `/api/payments/daily` | Get daily summary |

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/)
- Node.js 18+

### Smart Contract Development

```bash
# Build contracts
forge build

# Run tests
forge test

# Deploy to Sepolia
forge script script/DeployFullSystem.s.sol --rpc-url sepolia --broadcast
```

### Workers API Development

```bash
cd workers

# Local development
wrangler dev

# Deploy
wrangler deploy

# D1 database operations
wrangler d1 execute japoint-payments --file=./schema.sql
```

### Frontend Deployment

Frontend is automatically deployed to Cloudflare Pages when pushed to `gh-pages` branch.

## Deployment Info

| Service | URL / ID |
|---------|----------|
| Cloudflare Pages | https://japoint-payment.pages.dev |
| Cloudflare Workers | https://japoint-api.kkuejo.workers.dev |
| D1 Database | `15ff8ac7-fea5-491b-adf3-dcca95c5534c` |
| GitHub Repo | kkuejo/japoint-payment |

## Project Structure

```
.
├── src/                      # Smart contracts
│   ├── JAPoint.sol           # JAPT reward token
│   ├── JAPointMint.sol       # JAPT distribution
│   ├── JPYCWrapper.sol       # JPYC notification wrapper
│   ├── Transfer10.sol        # 1% fee payment processor
│   ├── Transfer5.sol         # 0.5% fee payment processor
│   └── ITokenReceiver.sol    # Notification interface
├── test/                     # Contract tests
├── script/                   # Deployment scripts
├── workers/                  # Cloudflare Workers API
│   ├── src/index.js          # API endpoints
│   ├── schema.sql            # D1 database schema
│   └── wrangler.toml         # Workers config
├── index.html                # Shop dashboard
├── mobile-payment.html       # Mobile payment page
├── dashboard.html            # Admin dashboard
├── add-japt.html             # Add JAPT to MetaMask
└── system.md                 # Full system documentation
```

## Documentation

- [system.md](system.md) - Full system architecture and technical details
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment instructions
- [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) - Setup guide

## License

MIT
