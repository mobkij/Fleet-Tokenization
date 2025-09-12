# 🚛 Fleet Tokenization Smart Contract

> Transform physical fleet assets into tradeable digital tokens and earn revenue from daily operations! 💰

## 🎯 Overview

Fleet Tokenization allows asset owners to fractionalize their buses, trucks, and bikes into digital tokens. Investors can purchase these tokens and earn revenue from the daily operations of these vehicles.

## ✨ Features

- 🚌 **Asset Registration**: Register buses, trucks, or bikes as tokenized assets
- 💎 **Token Fractionalization**: Split assets into tradeable tokens
- 💰 **Revenue Distribution**: Automated revenue sharing based on token ownership
- 🔄 **Token Trading**: Transfer tokens between investors
- 📊 **Revenue Tracking**: Monitor earnings and claim rewards
- ⚡ **Real-time Updates**: Update asset performance metrics

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for interaction

### Installation

```bash
git clone https://github.com/your-username/Fleet-Tokenization
cd Fleet-Tokenization
clarinet check
```

## 📋 Contract Functions

### 🏗️ Asset Management

#### `register-asset`
Register a new fleet asset for tokenization.

```clarity
(register-asset "Bus" "Mercedes Sprinter" "ABC123" u1000 u10000)
```

Parameters:
- `asset-type`: Type of vehicle (Bus, Truck, Bike)
- `model`: Vehicle model
- `license-plate`: License plate number
- `daily-revenue`: Expected daily revenue in microSTX
- `token-supply`: Total tokens to create

#### `deactivate-asset`
Deactivate an asset (owner only).

```clarity
(deactivate-asset u1)
```

#### `update-daily-revenue`
Update the daily revenue expectation (owner only).

```clarity
(update-daily-revenue u1 u1200)
```

### 💰 Token Operations

#### `purchase-tokens`
Buy tokens from an asset owner.

```clarity
(purchase-tokens u1 u100 u5000)
```

Parameters:
- `asset-id`: ID of the asset
- `amount`: Number of tokens to purchase
- `price`: Total price in microSTX

#### `transfer-asset-tokens`
Transfer tokens to another user.

```clarity
(transfer-asset-tokens u1 u50 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### 📈 Revenue Management

#### `add-revenue`
Add revenue to the pool (asset owner only).

```clarity
(add-revenue u1 u1000)
```

#### `claim-revenue`
Claim your share of revenue (once per day).

```clarity
(claim-revenue u1)
```

## 🔍 Read-Only Functions

### Asset Information
- `get-asset`: Get asset details
- `get-total-assets`: Get total number of assets
- `get-asset-holders`: Get list of token holders for an asset

### Token Information
- `get-asset-tokens`: Get token balance for a holder
- `get-user-claimable-revenue`: Calculate claimable revenue

### Revenue Information
- `get-revenue-pool`: Get available revenue for an asset
- `get-total-revenue`: Get total revenue across all assets
- `can-claim-revenue`: Check if user can claim revenue (24-hour cooldown)

## 🎮 Usage Examples

### 1. 🚌 Register a Bus Fleet Asset

```clarity
;; Register a city bus
(contract-call? .fleet-tokenization register-asset 
  "Bus" 
  "Volvo 7900" 
  "CTY001" 
  u2000 
  u20000)
```

### 2. 💸 Invest in Fleet Tokens

```clarity
;; Purchase 1000 tokens for 50,000 microSTX
(contract-call? .fleet-tokenization purchase-tokens 
  u1 
  u1000 
  u50000)
```

### 3. 📊 Add Daily Revenue

```clarity
;; Asset owner adds daily earnings
(contract-call? .fleet-tokenization add-revenue 
  u1 
  u1800)
```

### 4. 💰 Claim Your Revenue Share

```clarity
;; Claim your proportional revenue share
(contract-call? .fleet-tokenization claim-revenue u1)
```

## 🏛️ Contract Architecture

The contract uses the following data structures:

- **Assets Map**: Stores fleet asset information
- **Asset Tokens Map**: Tracks token ownership per asset
- **Revenue Pool Map**: Manages revenue distribution
- **Asset Holders List**: Maintains investor lists

## 🔐 Security Features

- ✅ Owner-only functions for asset management
- ✅ Balance validation for all transfers
- ✅ 24-hour cooldown between revenue claims
- ✅ Input validation and error handling
- ✅ Protected revenue distribution logic

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For questions and support, please open an issue in the GitHub repository.

---

*Made with ❤️ for the Stacks ecosystem*
