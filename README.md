# JAPOINT System

A complete stablecoin payment and reward system built with Solidity and Foundry, featuring automatic payment processing with JPYD (Japanese Yen-pegged stablecoin), JAPoint rewards, and gas-optimized architecture.

## System Overview

This project consists of 5 main contracts that work together to provide seamless payment processing with automatic reward distribution.

### 1. JPYD (JPY Digital)
- Japanese Yen-pegged stablecoin compliant with JPYC specifications
- ERC20-compliant token with 18 decimals
- Mintable and burnable
- EIP-2612 permit functionality
- **Automatic notification system**: Automatically triggers payment processing when tokens are sent to supported contracts

### 2. JAPoint (XA Point)
- ERC20 reward token with 18 decimals (Symbol: JAPT)
- Mintable by owner (initially the contract owner at deployment)
- Burnable by token holders
- Earned through payment transactions

### 3. JAPointMint
- **Gas-optimized distribution contract** (uses pre-minted token reserve)
- Holds 1 trillion JAPT (1,000,000,000,000) as distribution reserve
- Users approve JPYD and call `transferJAPoint(recipient)` to receive JAPoint
- JPYD is transferred to the designated company address
- 1:1 exchange rate (1 JPYD = 1 JAPT)
- **No minting per transaction** - significantly reduces gas costs

### 4. Transfer10
- Payment processing contract with automatic reward functionality
- **3 payment processing methods**:
  1. **Automatic**: Simply send JPYD directly via MetaMask transfer (gas limit: 500,000+)
  2. **deposit(amount)**: Specify exact amount to process
  3. **processPayment()**: Process all approved JPYD
- Receives JPYD payments and distributes:
  - 1% to JAPointMint (user receives equivalent JAPoint as reward)
  - 99% to shop address (payment to merchant)
- Simplifies payment+reward process in one transaction

### 5. Transfer5
- Payment processing contract with automatic reward functionality similar to Transfer10
- **Difference from Transfer10**: Different reward allocation
- **3 payment processing methods**:
  1. **Automatic**: Simply send JPYD directly via MetaMask transfer (gas limit: 500,000+)
  2. **deposit(amount)**: Specify exact amount to process
  3. **processPayment()**: Process all approved JPYD
- Receives JPYD payments and distributes:
  - 0.5% to JAPointMint (user receives equivalent JAPoint as reward)
  - 99.5% to shop address (payment to merchant)
- Lower reward rate than Transfer10, more funds to shop

## Key Features

### Automatic Payment Processing
Send JPYD directly to Transfer10 address from MetaMask or any wallet - **no function call needed**!
- JPYD detects that recipient is Transfer10 contract
- Automatically calls `onTokenReceived()`
- Processes payment distribution in same transaction
- **Gas requirement**: ~186,728 gas (set gas limit to 500,000 for safety)

### Gas-Optimized Architecture
- **Transfer-based distribution** instead of per-transaction minting
- **Pre-minted reserve**: 1 trillion JAPT minted to JAPointMint at deployment
- Reduces gas costs by ~2.2% compared to mint-per-transaction approach
- More secure: JAPointMint doesn't need to be owner of JAPoint

## How It Works

### Method 1: Automatic Payment Processing (Recommended)

**Just send JPYD to Transfer10 address!**

```bash
# Using cast (with gas limit set to 500,000)
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  500000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**What happens automatically:**
1. JPYD transfer completes
2. JPYD detects Transfer10 is a contract
3. Automatically calls `Transfer10.onTokenReceived()`
4. Transfer10 processes payment:
   - Approves 1% to JAPointMint
   - Calls `transferJAPoint(sender)` - sender receives JAPT reward
   - Transfers 99% to shop
   - Emits `PaymentProcessed` event
5. Everything completes in 1 transaction!

### Method 2: Manual Processing with deposit()

```bash
# 1. Approve JPYD to Transfer10
cast send <JPYD_ADDRESS> \
  "approve(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# 2. Deposit specific amount
cast send <TRANSFER10_ADDRESS> \
  "deposit(uint256)" \
  5000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### Method 3: Automatic Payment Processing with Transfer5 (0.5% Reward)

Transfer5 works similarly to Transfer10 but with 0.5% reward rate:

```bash
# Using cast (with gas limit set to 500,000)
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER5_ADDRESS> \
  500000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**What happens automatically:**
1. JPYD transfer completes
2. JPYD detects Transfer5 is a contract
3. Automatically calls `Transfer5.onTokenReceived()`
4. Transfer5 processes payment:
   - Approves 0.5% to JAPointMint
   - Calls `transferJAPoint(sender)` - sender receives JAPT reward
   - Transfers 99.5% to shop
   - Emits `PaymentProcessed` event
5. Everything completes in 1 transaction!

### Method 4: Direct JAPoint Exchange

Exchange JPYD for JAPoint directly via JAPointMint:

```bash
# 1. Approve JPYD to JAPointMint
cast send <JPYD_ADDRESS> \
  "approve(address,uint256)" \
  <JAPOINTMINT_ADDRESS> \
  1000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# 2. Transfer JAPoint (JPYD goes to company)
cast send <JAPOINTMINT_ADDRESS> \
  "transferJAPoint(address)" \
  <RECIPIENT_ADDRESS> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## Contract Details

| Contract | Name | Symbol | Decimals | Features |
|----------|------|--------|----------|----------|
| JPYD | JPY Digital | JPYD | 18 | Mintable, Burnable, Permit, Auto-notification |
| JAPoint | XA Point | JAPT | 18 | Mintable (owner only), Burnable |
| JAPointMint | - | - | - | Pre-minted reserve (1T JAPT), 1:1 exchange, transfer to company |
| Transfer10 | - | - | - | Auto-processing, 1% reward, 99% to shop |
| Transfer5 | - | - | - | Auto-processing, 0.5% reward, 99.5% to shop |

All contracts are based on OpenZeppelin Contracts v5.5.0 and use Solidity ^0.8.20.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.20
- Ethereum wallet with testnet ETH for Sepolia deployment, or Anvil for local testing
- RPC endpoint (Alchemy, Infura, etc.)

## Installation

```bash
# Clone the repository
git clone https://github.com/kkuejo/japoint-payment
cd JAPOINT

# Install dependencies (OpenZeppelin Contracts and forge-std)
forge install
```

Dependencies:
- OpenZeppelin Contracts v5.5.0
- forge-std v1.11.0

## Build

```bash
forge build
```

## Test

Run all tests:
```bash
forge test
```

Run tests with verbose output:
```bash
forge test -vv
```

Run tests with gas reports:
```bash
forge test --gas-report
```

Run specific test contract:
```bash
forge test --match-contract Transfer10Test -vv
```

Run specific test function:
```bash
forge test --match-test testAutomaticProcessingViaTransfer -vv
```

Test coverage includes:
- Unit tests for all contracts
- Integration tests for payment flows
- Fuzz tests for edge cases
- Automatic processing tests

## Local Development with Anvil

### 1. Start Anvil

```bash
anvil
```

### 2. Deploy Full System

```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
COMPANY_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
SHOP_ADDRESS=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC \
forge script script/DeployFullSystem.s.sol:DeployFullSystem \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

This deploys:
- JPYD with 10M initial supply
- JAPoint
- JAPointMint with 1T JAPT reserve
- Transfer10 for payment processing (1% reward)
- Transfer5 for payment processing (0.5% reward)

### 3. Test Automatic Processing

```bash
# Send JPYD directly to Transfer10 (automatic processing)
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  500000000000000000000 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --rpc-url http://127.0.0.1:8545 \
  --gas-limit 500000
```

## 🌐 Sepolia Testnet Deployment

### Current Deployed Contracts (2025-11-22)

JAPOINT system is live on Sepolia testnet:

| Contract | Address | Etherscan |
|----------|---------|-----------|
| **JPYD** | `0xdD870D138DC6081E664c5127226e815cc4C6f87D` | [View](https://sepolia.etherscan.io/address/0xdD870D138DC6081E664c5127226e815cc4C6f87D) |
| **JAPoint** | `0x2eDf302548B23e9F599e483aE79cda6D8774c6fC` | [View](https://sepolia.etherscan.io/address/0x2eDf302548B23e9F599e483aE79cda6D8774c6fC) |
| **JAPointMint** | `0x24FC91c3895042ABaCD0245eC8edD521BB8a29da` | [View](https://sepolia.etherscan.io/address/0x24FC91c3895042ABaCD0245eC8edD521BB8a29da) |
| **JPYDWrapper** | `0xa30042F978913cE9B466e204E7F729AeBCb3c624` | [View](https://sepolia.etherscan.io/address/0xa30042F978913cE9B466e204E7F729AeBCb3c624) |
| **Transfer10** | `0xA3963E928B35Ac06cC519b2a1BbBc3F27aCf0460` | [View](https://sepolia.etherscan.io/address/0xA3963E928B35Ac06cC519b2a1BbBc3F27aCf0460) |
| **Transfer5** | `0x74F6CfD89751a677E74130752483a530e27D4819` | [View](https://sepolia.etherscan.io/address/0x74F6CfD89751a677E74130752483a530e27D4819) |

**Mobile Payment URL**: https://kkuejo.github.io/japoint-payment/

More info: [DEPLOYMENT.md](DEPLOYMENT.md) | [Setup Instructions](SETUP_INSTRUCTIONS.md) | [Usage Guide](USAGE_GUIDE.md)

### Deploy New Instance

#### 1. Set Environment Variables

```bash
export PRIVATE_KEY=your_private_key_here
export COMPANY_ADDRESS=your_company_address_here
export SHOP_ADDRESS=your_shop_address_here
```

Or create a `.env` file (already added to `.gitignore`).

#### 2. Get Sepolia ETH

Faucet: https://sepoliafaucet.com/

#### 3. Run Deployment

```bash
source .env

forge script script/DeployFullSystem.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --slow \
  --legacy
```

## Usage Examples

### Automatic Processing (Easiest Way)

**Example**: Pay 10,000 JPYD to shop via Transfer10

```bash
# Just send JPYD directly - everything processed automatically!
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**Result:**
- You automatically receive: 100 JAPT (1% reward)
- Shop receives: 9,900 JPYD (99% payment)
- Company receives: 100 JPYD (from JAPointMint)
- All in one transaction!

**Important**: Set gas limit to 500,000+ for automatic processing

### Automatic Processing with Transfer5 (0.5% Reward)

**Example**: Pay 10,000 JPYD to shop via Transfer5

```bash
# Just send JPYD directly - everything processed automatically!
cast send <JPYD_ADDRESS> \
  "transfer(address,uint256)" \
  <TRANSFER5_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --gas-limit 500000
```

**Result:**
- You automatically receive: 50 JAPT (0.5% reward)
- Shop receives: 9,950 JPYD (99.5% payment)
- Company receives: 50 JPYD (from JAPointMint)
- All in one transaction!

**Important**: Set gas limit to 500,000+ for automatic processing

### Manual Processing with deposit()

```bash
# 1. Approve JPYD to Transfer10
cast send <JPYD_ADDRESS> \
  "approve(address,uint256)" \
  <TRANSFER10_ADDRESS> \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# 2. Process payment with specific amount
cast send <TRANSFER10_ADDRESS> \
  "deposit(uint256)" \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### Direct JAPoint Exchange

Exchange JPYD for JAPT directly:

```bash
# 1. Approve JPYD to JAPointMint
cast send <JPYD_ADDRESS> \
  "approve(address,uint256)" \
  <JAPOINTMINT_ADDRESS> \
  1000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# 2. Get JAPoint (JPYD goes to company)
cast send <JAPOINTMINT_ADDRESS> \
  "transferJAPoint(address)" \
  <RECIPIENT_ADDRESS> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### Check Balances

Check JPYD balance:
```bash
cast call <JPYD_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <WALLET_ADDRESS> \
  --rpc-url $RPC_URL
```

Check JAPoint balance:
```bash
cast call <JAPOINT_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <WALLET_ADDRESS> \
  --rpc-url $RPC_URL
```

Check JAPointMint reserve:
```bash
cast call <JAPOINT_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <JAPOINTMINT_ADDRESS> \
  --rpc-url $RPC_URL
```

### Admin Functions

Update company address (JAPointMint owner only):
```bash
cast send <JAPOINTMINT_ADDRESS> \
  "updateCompanyAddress(address)" \
  <NEW_COMPANY_ADDRESS> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

Update shop address (Transfer10 owner only):
```bash
cast send <TRANSFER10_ADDRESS> \
  "updateShopAddress(address)" \
  <NEW_SHOP_ADDRESS> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## Contract Interactions

### Automatic Payment Flow (via transfer)

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
  |                    |                      |--transferJAPoint-->|                 |                |
  |                    |                      |  (sender)         |                 |                |
  |                    |                      |                   |                 |                |
  |                    |                      |                   |--transferFrom->|                 |
  |                    |<--JPYD(5)------------|                   |(from T10)      |                |
  |                    |                      |                   |                |                |
  |                    |                      |                   |--transfer----->|                |
  |<--JAPT(5)-------------------------------------------(reward)---|                |                |
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

### Manual Payment Flow (via deposit)

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
  |                        |--transferJAPoint---->|               |                |
  |                        |  (sender)           |               |                |
  |                        |                     |               |                |
  |                        |                     |--transferFrom>|                |
  |                        |                     |(5 JAPT from    |                |
  |                        |                     | reserve)      |                |
  |<----JAPT reward (5)-------------------------|               |                |
  |                        |                     |               |                |
  |                        |                     |--transfer JPYD(5)------------>|
  |                        |                     |               |          (Company)
  |                        |                     |               |                |
  |                        |--transfer JPYD(495)-------------------------------->|
  |                        |                     |               |           (Shop)
```

## Gas Costs

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Automatic processing (transfer) | ~186,728 | Set gas limit to 500,000+ |
| Manual deposit() | ~155,000 | Approximate |
| Direct transferJAPoint() | ~120,000 | Approximate |

Gas savings from transfer-based architecture: **~2.2%** reduction compared to mint-per-transaction.

## Security Considerations

- **Pre-minted reserve**: JAPointMint holds 1T JAPT - ensure sufficient reserve for expected usage
- **Approval required**: Users must approve JPYD before using `deposit()`, `processPayment()`, or `transferJAPoint()` methods
- **Automatic transfer**: Direct `transfer()` to Transfer10 or Transfer5 doesn't require approval but needs gas limit 500,000+
- **Gas limit for automatic processing**: Automatic processing via transfer requires gas limit set to 500,000+
- **Address management**: Company and shop addresses can be updated by contract owner
- **Token recovery**: Emergency function (`recoverTokens()`) available to recover accidentally sent tokens (except JPYD sent via automatic-processing `transfer()`)
- **Private keys**: Never commit private keys to version control
- **Testing**: All contracts have comprehensive test coverage including fuzz tests
- **ITokenReceiver interface**: Transfer10 and Transfer5 implement this - prevents unauthorized automatic processing
- **Transfer vs TransferFrom**: Only direct `transfer()` triggers automatic processing; `transferFrom()` used in contracts does not trigger notification

## Technical Details

### Automatic Processing Implementation

JPYD contract:
- Overrides `transfer()` to check if recipient is a contract
- Makes low-level `call()` with `onTokenReceived()` selector
- Uses low-level call to forward all available gas (no gas limit specification)
- Emits `NotificationAttempt` event to track success/failure
- Only `transfer()` triggers automatic processing; `transferFrom()` does not

Transfer10 contract:
- Implements `ITokenReceiver` interface
- `onTokenReceived()` verifies caller is JPYD contract
- Processes payment distribution in same transaction
- Emits events for tracking

### JAPointMint Reserve System

- Mints 1 trillion JAPT to JAPointMint at deployment
- Uses `transfer()` instead of per-transaction `mint()`
- Gas savings: no ownership transfer or mint permissions needed
- More secure: JAPointMint doesn't need to be owner of JAPoint
- Reserve can be monitored via `balanceOf(JAPointMint)`

## Development

Format code:
```bash
forge fmt
```

Generate gas snapshots:
```bash
forge snapshot
```

Clean build artifacts:
```bash
forge clean
```

## Project Structure

```
.
├── src/
│   ├── JPYD.sol              # Standard ERC20-compliant JPY-pegged stablecoin (only mint, decimals added)
│   ├── JPYDWrapper.sol       # Auto-notification wrapper for JPYD/JPYC
│   ├── JAPoint.sol            # XA Point reward token
│   ├── JAPointMint.sol        # Transfer-based JPYD → JAPoint exchange
│   ├── Transfer10.sol        # Payment processing with auto-reward (1% reward)
│   ├── Transfer5.sol         # Payment processing with auto-reward (0.5% reward)
│   ├── ITokenReceiver.sol    # Interface for automatic notification
├── test/
│   ├── JPYD.t.sol            # JPYD tests
│   ├── JAPointMint.t.sol      # JAPoint and JAPointMint tests
│   └── Transfer10.t.sol      # Transfer10 tests (including automatic processing)
├── script/
│   └── DeployFullSystem.s.sol        # All contracts (JPYD, JAPoint, JAPointMint, JPYDWrapper, Transfer10, Transfer5) with 1T JAPT reserve
├── foundry.toml              # Foundry configuration
└── README.md
```

## Use Cases

### Scenario 1: Easy Payment via MetaMask (Recommended)
1. Customer opens MetaMask
2. Sends 10,000 JPYD to Transfer10 contract address
3. **Everything processed automatically in 1 transaction:**
   - Shop receives 9,900 JPYD (99%)
   - Customer receives 100 JAPT (1% reward)
   - Company receives 100 JPYD
4. Customer can immediately see JAPT reward in wallet

### Scenario 2: E-commerce Integration
1. E-commerce site displays Transfer10 address as payment destination
2. Customer sends JPYD from any wallet (gas limit 500,000+)
3. Backend monitors `PaymentProcessed` event
4. Order automatically confirmed when event detected
5. Customer automatically receives loyalty points (JAPT)

### Scenario 3: Direct JAPoint Purchase
1. User wants to buy JAPoint with JPYD
2. User approves and calls `transferJAPoint()`
3. User receives JAPT from pre-minted reserve
4. Company receives JPYD
5. No new tokens minted (gas efficient)

### Scenario 4: Accumulate Rewards with Multiple Payments
1. Customer makes multiple purchases via Transfer10
2. Each purchase automatically earns 1% JAPT reward
3. Rewards accumulate in customer's wallet
4. Customer can trade or use accumulated JAPT

## Comparison: Before and After Optimization

| Feature | Before (Mint) | After (Transfer) |
|---------|--------------|------------------|
| JAPoint Distribution | Mint per transaction | Transfer from reserve |
| Gas Cost | ~190,924 | ~186,728 (-2.2%) |
| JAPointMint Ownership | Must own JAPoint | No ownership needed |
| Reserve | N/A | 1 trillion JAPT |
| Function Name | `mint()` | `transferJAPoint()` |
| Security | Owner-controlled | Simpler, more secure |

## Troubleshooting

### "Out of Gas" Error in Automatic Processing
- **Solution**: Increase gas limit to 500,000 or higher
- Automatic processing requires more gas due to nested contract calls

### "Only JPYD tokens accepted" Error
- **Solution**: Only send JPYD tokens to Transfer10, not other tokens
- Transfer10 only accepts JPYD for automatic processing

### "Insufficient JAPoint reserve" Error
- **Solution**: JAPointMint reserve depleted, need to add more JAPT
- Check reserve: `cast call <JAPOINT> "balanceOf(address)" <JAPOINTMINT>`

### Automatic Processing Not Triggered
- **Solution**: Ensure using `transfer()` not `transferFrom()`
- Only direct `transfer()` triggers automatic processing
- `transferFrom()` is used in contracts and doesn't trigger notification

## License

MIT

## Foundry Documentation

For more information on Foundry:
- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Documentation](https://book.getfoundry.sh/forge/)
- [Cast Documentation](https://book.getfoundry.sh/cast/)
