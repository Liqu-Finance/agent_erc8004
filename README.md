# 🤖 ERC-8004 Agent Registries

**On-chain identity, reputation, and validation registries for trustless AI agents**

## 📋 Overview

ERC-8004 Agent Registries is a standard implementation for managing identity, reputation, and validation of AI agents on-chain. This system provides a trust layer infrastructure for autonomous agents operating in the blockchain ecosystem.

**Standard:** [ERC-8004 - Trustless Agents](https://eips.ethereum.org/EIPS/eip-8004)

## 🎯 Key Features

- ✅ **Identity Registry**: Central registry for agent identities with domain & address mapping
- ✅ **Reputation Registry**: Feedback authorization system between agents
- ✅ **Validation Registry**: Independent validation requests & responses
- ✅ **Spam Protection**: Registration fee to prevent spam registrations
- ✅ **Domain System**: Human-readable agent domains (`agent.example.com`)
- ✅ **Trustless**: Fully on-chain, no centralized authority

## 📁 Project Structure

```
agent-erc8004/
├── src/
│   ├── IdentityRegistry.sol        # Agent identity & domain registry
│   ├── ReputationRegistry.sol      # Feedback authorization system
│   ├── ValidationRegistry.sol      # Validation request/response system
│   └── interfaces/
│       ├── IIdentityRegistry.sol
│       ├── IReputationRegistry.sol
│       └── IValidationRegistry.sol
├── script/
│   └── DeployERC8004.s.sol        # Deployment script
└── test/
    └── (test files)
```

## 🏗️ Architecture

### 1. IdentityRegistry

**Purpose:** Central registry for all agent identities

**Features:**

- Register agents with domain and address
- Domain-to-agent and address-to-agent mapping
- Update domain/address for existing agents
- Registration fee for spam protection (0 ETH by default)

**Key Functions:**

```solidity
// Register new agent
function newAgent(string calldata agentDomain, address agentAddress)
    external payable returns (uint256 agentId);

// Update existing agent
function updateAgent(uint256 agentId, string calldata newDomain, address newAddress)
    external returns (bool);

// Resolve by domain
function resolveByDomain(string calldata domain)
    external view returns (AgentInfo memory);

// Resolve by address
function resolveByAddress(address agentAddress)
    external view returns (AgentInfo memory);
```

**Data Structure:**

```solidity
struct AgentInfo {
    uint256 agentId;          // Unique agent ID (starts from 1)
    string agentDomain;       // Domain (e.g., "agent.example.com")
    address agentAddress;     // EVM address
}
```

### 2. ReputationRegistry

**Purpose:** Feedback authorization system for agent interactions

**Features:**

- Server agents authorize feedback from client agents
- Track authorization status between agent pairs
- Unique feedback authorization IDs
- Prevents unauthorized feedback

**Key Functions:**

```solidity
// Server authorizes feedback from client
function acceptFeedback(uint256 agentClientId, uint256 agentServerId)
    external;

// Check if feedback is authorized
function isFeedbackAuthorized(uint256 agentClientId, uint256 agentServerId)
    external view returns (bool isAuthorized, bytes32 feedbackAuthId);
```

**Use Case:**

```
1. Client agent (ID: 1) requests service from Server agent (ID: 2)
2. After service completion, Server calls acceptFeedback(1, 2)
3. Now Client can submit feedback about Server's service
4. Off-chain systems can verify authorization via feedbackAuthId
```

### 3. ValidationRegistry

**Purpose:** Independent validation requests for data verification

**Features:**

- Request validation from validator agents
- Submit validation responses (approve/reject)
- Expiration mechanism (1000 blocks default)
- Track validation status per data hash

**Key Functions:**

```solidity
// Request validation
function validationRequest(
    uint256 agentValidatorId,
    uint256 agentServerId,
    bytes32 dataHash
) external;

// Submit validation response
function validationResponse(
    bytes32 dataHash,
    uint8 validationAnswer  // 1 = approve, 2 = reject
) external;

// Get validation result
function validationResult(bytes32 dataHash)
    external view returns (uint8 result);
```

**Validation Flow:**

```
1. Server agent (ID: 2) requests validation for data hash
2. ValidationRegistry emits event to Validator agent (ID: 3)
3. Validator reviews data and calls validationResponse()
4. Server can check validation result on-chain
```

## 🚀 Quick Start

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

### Build & Test

```bash
# Compile contracts
forge build

# Run tests
forge test

# Run with gas report
forge test --gas-report

# Run with coverage
forge coverage
```

## 📦 Deployment

### Environment Setup

Create `.env` file:

```bash
# Network RPC
UNICHAIN_SEPOLIA_RPC_URL=https://sepolia.unichain.org

# Deployment
PRIVATE_KEY=your_private_key_here

# Verification
UNISCAN_API_KEY=your_uniscan_api_key
```

### Deploy to Network

```bash
# Deploy all registries
forge script script/DeployERC8004.s.sol:DeployERC8004Script \
  --rpc-url $UNICHAIN_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $UNISCAN_API_KEY
```

**Output:**

```
IdentityRegistry:   0x...
ReputationRegistry: 0x...
ValidationRegistry: 0x...

Agents registered:
  Conservative: 0x5b6A404F8958E7e10028301549e61435925725Bf
  Balanced:     0x6c52aAD1Cbb66C0f666b62b36261d2f2205A8607
  Degen:        0x5B20B5a4Bba73bC6363fBE90E6b2Ab4fFF5C820e
```

### Configuration

Edit [script/DeployERC8004.s.sol](script/DeployERC8004.s.sol) to customize:

```solidity
// Agent addresses
address constant AGENT_1 = 0x...;
address constant AGENT_2 = 0x...;

// Agent domains
string constant DOMAIN_1 = "agent1.example.com";
string constant DOMAIN_2 = "agent2.example.com";
```

## 📖 Usage Examples

### Register New Agent

```solidity
// Get registration fee (0 ETH by default)
uint256 fee = identityRegistry.REGISTRATION_FEE();

// Register agent
uint256 agentId = identityRegistry.newAgent{value: fee}(
    "myagent.example.com",  // Domain
    0x1234...              // Agent address
);
```

### Update Agent Info

```solidity
// Must be called by current agent address
identityRegistry.updateAgent(
    agentId,
    "newdomain.example.com",  // New domain (or empty to keep current)
    0x5678...                // New address (or address(0) to keep current)
);
```

### Resolve Agent

```solidity
// By domain
IIdentityRegistry.AgentInfo memory agent =
    identityRegistry.resolveByDomain("myagent.example.com");

// By address
IIdentityRegistry.AgentInfo memory agent =
    identityRegistry.resolveByAddress(0x1234...);

// By ID
IIdentityRegistry.AgentInfo memory agent =
    identityRegistry.getAgent(agentId);
```

### Authorize Feedback

```solidity
// Server agent authorizes feedback from client
// Must be called by server agent's address
reputationRegistry.acceptFeedback(
    clientAgentId,
    serverAgentId
);

// Check authorization
(bool authorized, bytes32 authId) =
    reputationRegistry.isFeedbackAuthorized(clientAgentId, serverAgentId);
```

### Request Validation

```solidity
// Calculate data hash
bytes32 dataHash = keccak256(abi.encodePacked(data));

// Request validation
validationRegistry.validationRequest(
    validatorAgentId,   // Who should validate
    serverAgentId,      // Who is requesting
    dataHash           // What to validate
);

// Validator submits response
// Must be called by validator agent's address
validationRegistry.validationResponse(
    dataHash,
    1  // 1 = approve, 2 = reject
);

// Check result
uint8 result = validationRegistry.validationResult(dataHash);
// 0 = no response, 1 = approved, 2 = rejected
```

## 🔧 Configuration

### Registration Fee

Default: `0 ether` (no fee)

To change, edit [src/IdentityRegistry.sol](src/IdentityRegistry.sol):

```solidity
uint256 public constant REGISTRATION_FEE = 0.005 ether;  // Example: 0.005 ETH
```

**Note:** Fee is burned (locked in contract) for spam protection.

### Validation Expiration

Default: `1000 blocks` (~3.3 hours on most networks)

To change, edit [src/ValidationRegistry.sol](src/ValidationRegistry.sol):

```solidity
uint256 public constant EXPIRATION_SLOTS = 2000;  // Example: 2000 blocks
```

## 🔐 Security

### Security Features

- ✅ **Authorization Checks**: Only agent owner can update info
- ✅ **Duplicate Prevention**: No duplicate domains or addresses
- ✅ **Validation Checks**: All inputs validated
- ✅ **Expiration Mechanism**: Old validation requests expire
- ✅ **Immutable References**: Registry references are immutable

### Audit Status

⚠️ **Not Audited**: This is a reference implementation. DO NOT use in production without proper audit.

### Known Limitations

1. **No Agent Deletion**: Once registered, agents cannot be deleted (only updated)
2. **Fee is Burned**: Registration fee stays locked in contract (cannot be recovered)
3. **Single Validation**: Each data hash can only have one validation response
4. **No Reputation Score**: Registry only tracks authorization, not actual reputation scores

## 🧪 Testing

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testRegisterAgent -vvv

# Run with gas report
forge test --gas-report

# Run with coverage
forge coverage

# Fork testing
forge test --fork-url $UNICHAIN_SEPOLIA_RPC_URL
```

## 📊 Contract Interfaces

### IIdentityRegistry

```solidity
interface IIdentityRegistry {
    struct AgentInfo {
        uint256 agentId;
        string agentDomain;
        address agentAddress;
    }

    function newAgent(string calldata domain, address addr) external payable returns (uint256);
    function updateAgent(uint256 id, string calldata domain, address addr) external returns (bool);
    function getAgent(uint256 id) external view returns (AgentInfo memory);
    function resolveByDomain(string calldata domain) external view returns (AgentInfo memory);
    function resolveByAddress(address addr) external view returns (AgentInfo memory);
    function agentExists(uint256 id) external view returns (bool);
    function getAgentCount() external view returns (uint256);
}
```

### IReputationRegistry

```solidity
interface IReputationRegistry {
    function acceptFeedback(uint256 clientId, uint256 serverId) external;
    function isFeedbackAuthorized(uint256 clientId, uint256 serverId)
        external view returns (bool isAuthorized, bytes32 authId);
    function getFeedbackAuthId(uint256 clientId, uint256 serverId)
        external view returns (bytes32);
}
```

### IValidationRegistry

```solidity
interface IValidationRegistry {
    struct Request {
        uint256 agentValidatorId;
        uint256 agentServerId;
        bytes32 dataHash;
        uint256 timestamp;
    }

    function validationRequest(uint256 validatorId, uint256 serverId, bytes32 dataHash) external;
    function validationResponse(bytes32 dataHash, uint8 answer) external;
    function validationResult(bytes32 dataHash) external view returns (uint8);
    function getValidationRequest(bytes32 dataHash) external view returns (Request memory);
}
```

## 🔍 Events

### IdentityRegistry

```solidity
event AgentRegistered(uint256 indexed agentId, string agentDomain, address agentAddress);
event AgentUpdated(uint256 indexed agentId, string agentDomain, address agentAddress);
```

### ReputationRegistry

```solidity
event AuthFeedback(uint256 indexed agentClientId, uint256 indexed agentServerId, bytes32 feedbackAuthId);
```

### ValidationRegistry

```solidity
event ValidationRequestEvent(uint256 indexed agentValidatorId, uint256 indexed agentServerId, bytes32 dataHash);
event ValidationResponseEvent(uint256 indexed agentValidatorId, bytes32 indexed dataHash, uint8 validationAnswer);
```

## 🐛 Troubleshooting

### Common Issues

#### 1. "InsufficientFee()"

**Solution:** Send correct registration fee with `newAgent()` call

#### 2. "DomainAlreadyRegistered()"

**Solution:** Choose different domain, current one is taken

#### 3. "AddressAlreadyRegistered()"

**Solution:** Address already used by another agent

#### 4. "UnauthorizedUpdate()"

**Solution:** Only agent owner can update info

#### 5. "AgentNotFound()"

**Solution:** Agent ID doesn't exist in registry

### Debug Commands

```bash
# Check agent exists
cast call $IDENTITY_REGISTRY "agentExists(uint256)(bool)" 1 --rpc-url $RPC_URL

# Get agent info
cast call $IDENTITY_REGISTRY "getAgent(uint256)" 1 --rpc-url $RPC_URL

# Get agent count
cast call $IDENTITY_REGISTRY "getAgentCount()(uint256)" --rpc-url $RPC_URL

# Check feedback authorization
cast call $REPUTATION_REGISTRY \
  "isFeedbackAuthorized(uint256,uint256)(bool,bytes32)" \
  1 2 --rpc-url $RPC_URL

# Get validation result
cast call $VALIDATION_REGISTRY \
  "validationResult(bytes32)(uint8)" \
  0x1234... --rpc-url $RPC_URL
```

## 🌐 Integration Examples

### With CLMM Liquidity Agent

ERC-8004 registries are used by [CLMM Liquidity Agent](../uniswap-contract/README.md):

```solidity
// Verify agent is registered before authorization
IIdentityRegistry.AgentInfo memory info = identityRegistry.resolveByAddress(agent);
require(info.agentId != 0, "Agent not registered");

// Authorize agent
authorizedAgents[agent] = true;
```

### With Off-Chain Systems

```typescript
// Listen to registration events
identityRegistry.on("AgentRegistered", (agentId, domain, address) => {
  console.log(`New agent registered: ${domain} (${address})`);
  // Update off-chain database
});

// Query agent info
const agentInfo = await identityRegistry.resolveByDomain("agent.example.com");
```

## 📚 Additional Resources

### ERC-8004 Standard

- [EIP-8004 Specification](https://eips.ethereum.org/EIPS/eip-8004)
- [ERC-8004 Discussion](https://ethereum-magicians.org/t/erc-8004-trustless-agents/)

### Related Projects

- [CLMM Liquidity Agent](../uniswap-contract/README.md) - Uses ERC-8004 for agent trust
- [Autonomous Agents Framework](https://github.com/...)

### Development Tools

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## 🤝 Contributing

Contributions welcome! This is a reference implementation for ERC-8004.

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

## 📄 License

MIT License - see [LICENSE](../LICENSE) file for details

## 🙏 Acknowledgments

- ERC-8004 standard authors
- ChaosChain Labs for initial implementation
- Foundry team for development tools

---

**Built with ❤️ for trustless AI agent ecosystems**
