#!/bin/bash

# ============================================================
# Deploy ERC-8004 Contracts to Unichain Sepolia
# ============================================================
# 
# Prerequisites:
#   1. Foundry installed (https://book.getfoundry.sh/getting-started/installation)
#   2. Private key with testnet ETH on Unichain Sepolia
#   3. Get testnet ETH from Unichain Sepolia faucet
#
# Usage:
#   chmod +x script/deploy-unichain-sepolia.sh
#   ./script/deploy-unichain-sepolia.sh
#
# ============================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Unichain Sepolia Configuration
CHAIN_ID=1301
RPC_URL="${UNICHAIN_SEPOLIA_RPC_URL:-https://sepolia.unichain.org}"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   Deploy ERC-8004 Contracts to Unichain Sepolia${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable is not set${NC}"
    echo -e "${YELLOW}Usage: PRIVATE_KEY=your_private_key ./script/deploy-unichain-sepolia.sh${NC}"
    exit 1
fi

echo -e "${GREEN}Network:${NC} Unichain Sepolia"
echo -e "${GREEN}Chain ID:${NC} $CHAIN_ID"
echo -e "${GREEN}RPC URL:${NC} $RPC_URL"
echo ""

# Build contracts first
echo -e "${YELLOW}Building contracts...${NC}"
forge build

# Check if build was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"
echo ""

# Deploy contracts
echo -e "${YELLOW}Deploying contracts to Unichain Sepolia...${NC}"
echo ""

forge script script/Deploy.s.sol:Deploy \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --legacy \
    -vvvv

# Check deployment status
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}   Deployment Successful!${NC}"
    echo -e "${GREEN}============================================================${NC}"
    echo ""
    echo -e "${BLUE}Check your deployment on Unichain Sepolia Explorer:${NC}"
    echo -e "https://sepolia.uniscan.xyz/"
    echo ""
    echo -e "${YELLOW}Note: Broadcast files are saved in 'broadcast/' directory${NC}"
else
    echo -e "${RED}Deployment failed!${NC}"
    exit 1
fi
