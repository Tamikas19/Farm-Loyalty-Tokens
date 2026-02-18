# 🌾 Farm Loyalty Tokens

**A decentralized platform connecting consumers directly with farms through blockchain-powered loyalty rewards!** 

Buy fresh produce directly from local farms and earn loyalty tokens that unlock exclusive benefits including discounts, farm recipes, and unique farm visit experiences. 🚜✨

## 🌟 Features

- **🛒 Direct Farm Purchases**: Buy produce directly from registered farms
- **🪙 Loyalty Token Rewards**: Earn tokens with every purchase
- **💰 Discount System**: Redeem tokens for discounts on future purchases
- **👨‍🍳 Recipe Library**: Unlock exclusive farm recipes using tokens
- **🏡 Farm Visits**: Book unique farm experiences with token rewards
- **📊 Transparent Tracking**: All transactions recorded on blockchain

## 🚀 Quick Start

### For Customers

1. **Purchase Produce** 🥕
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens purchase-produce produce-id payment-amount)
   ```

2. **Check Token Balance** 💰
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens get-token-balance your-principal)
   ```

3. **Redeem Discount** 🎫
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens redeem-discount farm-id discount-percent tokens-to-spend)
   ```

4. **Unlock Recipe** 📚
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens unlock-recipe recipe-id)
   ```

5. **Book Farm Visit** 🌿
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens book-farm-visit farm-id visit-date tokens-to-spend)
   ```

### For Farm Owners

1. **Register Your Farm** 🏛️
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens register-farm "Farm Name" "Location")
   ```

2. **Add Produce Items** 🍅
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens add-produce farm-id "Tomatoes" u1000000 u50)
   ```

3. **Add Recipes** 📖
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens add-recipe farm-id "Recipe Name" "Ingredients" "Instructions" u25)
   ```

4. **Confirm Farm Visits** ✅
   ```clarity
   (contract-call? .Farm-Loyalty-Tokens confirm-visit visit-id)
   ```

## 💡 How It Works

### 🔄 Token Economics
- **Earn**: Get loyalty tokens with every produce purchase
- **Redeem**: Use tokens for discounts (1-50% off)
- **Unlock**: Access exclusive farm recipes (25+ tokens typically)
- **Experience**: Book farm visits (100+ tokens minimum)

### 🎯 Key Benefits
- **For Consumers**: Fresh produce + loyalty rewards + unique experiences
- **For Farms**: Direct sales + customer retention + marketing platform
- **For Community**: Supporting local agriculture + transparent supply chain

## 📋 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `register-farm` | Register a new farm | name, location |
| `add-produce` | Add produce to farm inventory | farm-id, name, price, tokens-reward |
| `purchase-produce` | Buy produce and earn tokens | produce-id, payment |
| `redeem-discount` | Create discount voucher | farm-id, discount-percent, tokens-to-spend |
| `add-recipe` | Add recipe to library | farm-id, name, ingredients, instructions, token-cost |
| `unlock-recipe` | Unlock recipe with tokens | recipe-id |
| `book-farm-visit` | Book farm experience | farm-id, visit-date, tokens-to-spend |
| `confirm-visit` | Confirm visit booking (farm owner) | visit-id |
| `use-discount` | Apply discount voucher | user, redemption-id |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-farm-info` | Get farm details |
| `get-produce-info` | Get produce item details |
| `get-user-tokens` | Get user's token statistics |
| `get-token-balance` | Get user's current token balance |
| `get-recipe` | Get recipe details |
| `get-farm-visit` | Get farm visit details |

## 🛠️ Development Setup

1. **Install Clarinet**
   ```bash
   npm install -g @hirosystems/clarinet-cli
   ```

2. **Check Contract**
   ```bash
   clarinet check
   ```

3. **Run Tests**
   ```bash
   clarinet test
   ```

## 🏗️ Architecture

The contract uses several key data structures:

- **🏢 Farms**: Store farm information and ownership
- **🥬 Produce Items**: Track available produce with prices and rewards
- **💳 User Tokens**: Manage token balances and spending history
- **🎫 Discount Redemptions**: Handle discount vouchers with expiration
- **📚 Recipe Library**: Store exclusive farm recipes
- **🚌 Farm Visits**: Manage visit bookings and confirmations

## 🔒 Security Features

- **Owner Authorization**: Only farm owners can manage their farms
- **Balance Validation**: Prevents overspending of tokens
- **Expiration Logic**: Discount vouchers have time limits
- **Status Tracking**: Prevents double-redemption of benefits

## 🤝 Contributing

We welcome contributions! Please feel free to submit pull requests or open issues for bugs and feature requests.

## 📜 License

This project is open source and available under the [MIT License](LICENSE).

---

**🌱 Join the farm-to-table revolution with blockchain technology!** 

*Built with ❤️ for farmers and food lovers everywhere.*
