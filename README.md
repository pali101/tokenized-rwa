## Overview

This project implements a real-world asset tokenization system using ERC-1155 and ERC-20 standards.

- RWAToken: Represents fractional ownership of tokenized properties.
- RWAStableCoin: A stablecoin backed by tokenized real estate assets as collateral.

# Features

**RWAToken** (Hybrid of ERC-1155 and ERC-1400)

- Tokenizes real estate properties into fractional shares.
- Enforces KYC compliance via whitelisting.
- Allows property valuation updates and forced transfers.
- Enables burning of all shares for property liquidation.

**RWAStableCoin** (ERC-20)

- Mints stablecoins backed by tokenized real estate shares.
- Ensures a 120% collateralization ratio.
- Allows redemption of stablecoins for RWAToken shares.

# Deployed Contracts

- Sepolia

RWA Token address: 0x3C70Efa838AEB5e4b633D5D8667e6628369A9e10

RWA StableCoin address: 0x8f633895eA06c3f57417cFE481a551e016267661

- Citrea

RWA Token address: 0x1df8453136fd12070e837a7938650BfA6bdaF59e

RWA StableCoin address: 0x3BdEE8231d97c2F64E0bAA1F1BF6348Dd3CE2Cfd
