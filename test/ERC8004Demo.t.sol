// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/IdentityRegistry.sol";
import "../src/ReputationRegistry.sol";
import "../src/ValidationRegistry.sol";

/**
 * @title ERC8004Demo
 * @dev Comprehensive test suite demonstrating how ERC-8004 Trustless Agents works
 * @notice This test file serves as documentation for the protocol
 *
 * ╔════════════════════════════════════════════════════════════════════════════╗
 * ║                      ERC-8004: TRUSTLESS AGENTS                            ║
 * ╠════════════════════════════════════════════════════════════════════════════╣
 * ║  The protocol consists of three main registries:                           ║
 * ║                                                                            ║
 * ║  1. IDENTITY REGISTRY                                                      ║
 * ║     - Register AI agents with unique IDs                                   ║
 * ║     - Map domain names to agent addresses                                  ║
 * ║     - Lookup agents by ID, domain, or address                              ║
 * ║                                                                            ║
 * ║  2. REPUTATION REGISTRY                                                    ║
 * ║     - Enable feedback between agents                                       ║
 * ║     - Server agents authorize client agents to give feedback               ║
 * ║     - Creates unique feedback authorization IDs                            ║
 * ║                                                                            ║
 * ║  3. VALIDATION REGISTRY                                                    ║
 * ║     - Request independent validation of agent work                         ║
 * ║     - Validators respond with scores (0-100)                               ║
 * ║     - Time-limited validation requests                                     ║
 * ║                                                                            ║
 * ╚════════════════════════════════════════════════════════════════════════════╝
 */
contract ERC8004Demo is Test {
    // ============ Contracts ============
    IdentityRegistry public identityRegistry;
    ReputationRegistry public reputationRegistry;
    ValidationRegistry public validationRegistry;

    // ============ Test Actors ============

    /// @dev Alice - An AI trading agent
    address public alice = makeAddr("alice");

    /// @dev Bob - An AI data analysis agent
    address public bob = makeAddr("bob");

    /// @dev Charlie - An AI validation/auditing agent
    address public charlie = makeAddr("charlie");

    /// @dev Dave - A human user interacting with agents
    address public dave = makeAddr("dave");

    // ============ Agent IDs ============
    uint256 public aliceAgentId;
    uint256 public bobAgentId;
    uint256 public charlieAgentId;

    // ============ Setup ============

    function setUp() public {
        // Deploy the protocol contracts
        identityRegistry = new IdentityRegistry();
        reputationRegistry = new ReputationRegistry(address(identityRegistry));
        validationRegistry = new ValidationRegistry(address(identityRegistry));

        // Fund test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
        vm.deal(dave, 10 ether);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //                          IDENTITY REGISTRY DEMOS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice DEMO 1: Registering a New AI Agent
     * @dev Shows how an AI agent registers itself in the Identity Registry
     *
     * Flow:
     * 1. Agent owner calls newAgent() with domain and address
     * 2. System assigns unique agent ID
     * 3. Agent can now be discovered by ID, domain, or address
     */
    function test_Demo1_RegisterNewAgent() public {
        console.log("\n=== DEMO 1: Registering a New AI Agent ===\n");

        // Registration fee (currently 0 ETH for testing)
        uint256 registrationFee = identityRegistry.REGISTRATION_FEE();
        console.log("Registration Fee:", registrationFee, "wei");

        // Alice registers her trading agent
        vm.startPrank(alice);

        aliceAgentId = identityRegistry.newAgent{value: registrationFee}(
            "trading-agent.alice.eth", // Domain where AgentCard is hosted
            alice // Agent's EVM address
        );

        vm.stopPrank();

        console.log("Alice's Agent ID:", aliceAgentId);
        assertEq(aliceAgentId, 1, "First agent should have ID 1");

        // Verify agent was registered correctly
        IIdentityRegistry.AgentInfo memory agentInfo = identityRegistry
            .getAgent(aliceAgentId);

        console.log("Agent Domain:", agentInfo.agentDomain);
        console.log("Agent Address:", agentInfo.agentAddress);

        assertEq(agentInfo.agentDomain, "trading-agent.alice.eth");
        assertEq(agentInfo.agentAddress, alice);

        // Check total agent count
        uint256 agentCount = identityRegistry.getAgentCount();
        console.log("Total Registered Agents:", agentCount);
        assertEq(agentCount, 1);
    }

    /**
     * @notice DEMO 2: Resolving Agent by Domain
     * @dev Shows how to lookup an agent using their domain name
     *
     * Use Case: An agent wants to find another agent's address from their domain
     */
    function test_Demo2_ResolveAgentByDomain() public {
        console.log("\n=== DEMO 2: Resolving Agent by Domain ===\n");

        // Setup: Register Alice's agent
        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent(
            "trading-agent.alice.eth",
            alice
        );

        // Bob wants to find Alice's agent using her domain
        IIdentityRegistry.AgentInfo memory agentInfo = identityRegistry
            .resolveByDomain("trading-agent.alice.eth");

        console.log("Searching for: trading-agent.alice.eth");
        console.log("Found Agent ID:", agentInfo.agentId);
        console.log("Found Address:", agentInfo.agentAddress);

        assertEq(agentInfo.agentAddress, alice);
    }

    /**
     * @notice DEMO 3: Resolving Agent by Address
     * @dev Shows how to lookup an agent using their EVM address
     *
     * Use Case: Verify if an address belongs to a registered agent
     */
    function test_Demo3_ResolveAgentByAddress() public {
        console.log("\n=== DEMO 3: Resolving Agent by Address ===\n");

        // Setup: Register Alice's agent
        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent(
            "trading-agent.alice.eth",
            alice
        );

        // Lookup Alice by her address
        IIdentityRegistry.AgentInfo memory agentInfo = identityRegistry
            .resolveByAddress(alice);

        console.log("Searching for address:", alice);
        console.log("Found Agent ID:", agentInfo.agentId);
        console.log("Found Domain:", agentInfo.agentDomain);

        assertEq(agentInfo.agentDomain, "trading-agent.alice.eth");
    }

    /**
     * @notice DEMO 4: Updating Agent Information
     * @dev Shows how an agent can update their domain or address
     *
     * Use Case: Agent moves to a new domain or rotates their key
     */
    function test_Demo4_UpdateAgentInfo() public {
        console.log("\n=== DEMO 4: Updating Agent Information ===\n");

        // Setup: Register Alice's agent
        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent("old-domain.alice.eth", alice);

        console.log("Original Domain: old-domain.alice.eth");

        // Alice updates her domain (only she can do this)
        vm.prank(alice);
        bool success = identityRegistry.updateAgent(
            aliceAgentId,
            "new-domain.alice.eth", // New domain
            address(0) // Keep same address (pass zero address)
        );

        assertTrue(success, "Update should succeed");

        // Verify the update
        IIdentityRegistry.AgentInfo memory agentInfo = identityRegistry
            .getAgent(aliceAgentId);
        console.log("Updated Domain:", agentInfo.agentDomain);

        assertEq(agentInfo.agentDomain, "new-domain.alice.eth");
    }

    /**
     * @notice DEMO 5: Multiple Agents Registration
     * @dev Shows multiple agents registering in the ecosystem
     */
    function test_Demo5_MultipleAgentsRegistration() public {
        console.log("\n=== DEMO 5: Multiple Agents Registration ===\n");

        // Alice registers a trading agent
        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent("trading.alice.eth", alice);
        console.log("Alice (Trading Agent) ID:", aliceAgentId);

        // Bob registers a data analysis agent
        vm.prank(bob);
        bobAgentId = identityRegistry.newAgent("analytics.bob.eth", bob);
        console.log("Bob (Analytics Agent) ID:", bobAgentId);

        // Charlie registers a validation agent
        vm.prank(charlie);
        charlieAgentId = identityRegistry.newAgent(
            "validator.charlie.eth",
            charlie
        );
        console.log("Charlie (Validator Agent) ID:", charlieAgentId);

        // Verify all are registered
        uint256 totalAgents = identityRegistry.getAgentCount();
        console.log("\nTotal Registered Agents:", totalAgents);

        assertEq(totalAgents, 3);
        assertTrue(identityRegistry.agentExists(aliceAgentId));
        assertTrue(identityRegistry.agentExists(bobAgentId));
        assertTrue(identityRegistry.agentExists(charlieAgentId));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //                         REPUTATION REGISTRY DEMOS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice DEMO 6: Authorizing Feedback Between Agents
     * @dev Shows how a server agent authorizes a client agent to provide feedback
     *
     * Flow:
     * 1. Client agent (Alice) uses Server agent's (Bob) service
     * 2. Server agent (Bob) authorizes feedback from Alice
     * 3. A unique feedback authorization ID is generated
     *
     * Use Case: After Bob's analytics agent serves Alice's trading agent,
     *           Bob allows Alice to rate the service quality
     */
    function test_Demo6_AuthorizeFeedback() public {
        console.log("\n=== DEMO 6: Authorizing Feedback Between Agents ===\n");

        // Setup: Register both agents
        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent("trading.alice.eth", alice);

        vm.prank(bob);
        bobAgentId = identityRegistry.newAgent("analytics.bob.eth", bob);

        console.log("Alice (Client) Agent ID:", aliceAgentId);
        console.log("Bob (Server) Agent ID:", bobAgentId);

        // Bob's agent authorizes Alice's agent to give feedback
        // Only the SERVER agent can authorize feedback
        vm.prank(bob);
        reputationRegistry.acceptFeedback(
            aliceAgentId, // Client (who will give feedback)
            bobAgentId // Server (who will receive feedback)
        );

        console.log("\nBob authorized feedback from Alice!");

        // Verify the authorization
        (bool isAuthorized, bytes32 feedbackAuthId) = reputationRegistry
            .isFeedbackAuthorized(aliceAgentId, bobAgentId);

        console.log("Is Feedback Authorized:", isAuthorized);
        console.log("Feedback Auth ID:", vm.toString(feedbackAuthId));

        assertTrue(isAuthorized, "Feedback should be authorized");
        assertTrue(feedbackAuthId != bytes32(0), "Auth ID should be non-zero");
    }

    /**
     * @notice DEMO 7: Checking Feedback Authorization
     * @dev Shows how to check if feedback is authorized between two agents
     */
    function test_Demo7_CheckFeedbackAuthorization() public {
        console.log("\n=== DEMO 7: Checking Feedback Authorization ===\n");

        // Setup: Register agents
        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent("trading.alice.eth", alice);

        vm.prank(bob);
        bobAgentId = identityRegistry.newAgent("analytics.bob.eth", bob);

        // Check BEFORE authorization
        (bool beforeAuth, ) = reputationRegistry.isFeedbackAuthorized(
            aliceAgentId,
            bobAgentId
        );
        console.log("Before Authorization:", beforeAuth);
        assertFalse(beforeAuth);

        // Bob authorizes feedback
        vm.prank(bob);
        reputationRegistry.acceptFeedback(aliceAgentId, bobAgentId);

        // Check AFTER authorization
        (bool afterAuth, bytes32 authId) = reputationRegistry
            .isFeedbackAuthorized(aliceAgentId, bobAgentId);
        console.log("After Authorization:", afterAuth);
        console.log("Authorization ID:", vm.toString(authId));
        assertTrue(afterAuth);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //                         VALIDATION REGISTRY DEMOS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice DEMO 8: Requesting Validation of Agent Work
     * @dev Shows how to request independent validation of an agent's output
     *
     * Flow:
     * 1. Client has work/data from Server agent that needs validation
     * 2. Client creates a validation request with a data hash
     * 3. Designated Validator agent reviews and responds
     *
     * Use Case: Alice's trading decisions (from Bob's analytics) need
     *           independent validation by Charlie's auditing agent
     */
    function test_Demo8_RequestValidation() public {
        console.log("\n=== DEMO 8: Requesting Validation of Agent Work ===\n");

        // Setup: Register all agents
        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent("trading.alice.eth", alice);

        vm.prank(bob);
        bobAgentId = identityRegistry.newAgent("analytics.bob.eth", bob);

        vm.prank(charlie);
        charlieAgentId = identityRegistry.newAgent(
            "validator.charlie.eth",
            charlie
        );

        console.log("Alice (Client) Agent ID:", aliceAgentId);
        console.log("Bob (Server - Work Producer) Agent ID:", bobAgentId);
        console.log("Charlie (Validator) Agent ID:", charlieAgentId);

        // Create a hash of the data to be validated
        // This could be a hash of analytics results, predictions, etc.
        bytes32 dataHash = keccak256(
            abi.encodePacked(
                "Analytics Report: Market Prediction Q1 2026",
                block.timestamp
            )
        );

        console.log("\nData Hash:", vm.toString(dataHash));

        // Anyone can create a validation request
        validationRegistry.validationRequest(
            charlieAgentId, // Validator (who will review)
            bobAgentId, // Server (whose work is being validated)
            dataHash // Hash of the data to validate
        );

        console.log("Validation request created successfully!");

        // Verify the request exists
        IValidationRegistry.Request memory request = validationRegistry
            .getValidationRequest(dataHash);

        console.log("\n--- Request Details ---");
        console.log("Validator Agent ID:", request.agentValidatorId);
        console.log("Server Agent ID:", request.agentServerId);
        console.log("Block Number:", request.timestamp);
        console.log("Already Responded:", request.responded);

        assertEq(request.agentValidatorId, charlieAgentId);
        assertEq(request.agentServerId, bobAgentId);
        assertFalse(request.responded);
    }

    /**
     * @notice DEMO 9: Validator Responds to Validation Request
     * @dev Shows how a validator submits their validation response
     *
     * Response Score: 0-100
     *   - 0: Completely invalid/fraudulent
     *   - 50: Partially valid
     *   - 100: Fully valid and verified
     */
    function test_Demo9_ValidatorResponds() public {
        console.log(
            "\n=== DEMO 9: Validator Responds to Validation Request ===\n"
        );

        // Setup: Register agents
        vm.prank(bob);
        bobAgentId = identityRegistry.newAgent("analytics.bob.eth", bob);

        vm.prank(charlie);
        charlieAgentId = identityRegistry.newAgent(
            "validator.charlie.eth",
            charlie
        );

        // Create validation request
        bytes32 dataHash = keccak256("Test Analytics Data v1");

        validationRegistry.validationRequest(
            charlieAgentId,
            bobAgentId,
            dataHash
        );
        console.log(
            "Validation request created for data hash:",
            vm.toString(dataHash)
        );

        // Check request is pending
        (bool exists, bool pending) = validationRegistry.isValidationPending(
            dataHash
        );
        console.log("\nRequest Exists:", exists);
        console.log("Request Pending:", pending);
        assertTrue(pending);

        // Charlie (the validator) responds with a validation score
        // Only the designated validator can respond
        vm.prank(charlie);
        uint8 validationScore = 85; // 85% validity score
        validationRegistry.validationResponse(dataHash, validationScore);

        console.log("\nCharlie submitted validation score:", validationScore);

        // Verify the response
        (bool hasResponse, uint8 score) = validationRegistry
            .getValidationResponse(dataHash);

        console.log("\n--- Response Details ---");
        console.log("Has Response:", hasResponse);
        console.log("Validation Score:", score, "/ 100");

        assertTrue(hasResponse);
        assertEq(score, 85);

        // Request should no longer be pending
        (, bool stillPending) = validationRegistry.isValidationPending(
            dataHash
        );
        assertFalse(stillPending, "Request should no longer be pending");
    }

    /**
     * @notice DEMO 10: Complete Agent Interaction Flow
     * @dev End-to-end demonstration of the full ERC-8004 workflow
     *
     * Scenario:
     * 1. Three agents register in the ecosystem
     * 2. Alice requests analytics from Bob
     * 3. Bob serves Alice and authorizes feedback
     * 4. Alice requests validation of Bob's work from Charlie
     * 5. Charlie validates the work
     */
    function test_Demo10_CompleteWorkflow() public {
        console.log("\n");
        console.log(
            "================================================================"
        );
        console.log(
            "       DEMO 10: Complete ERC-8004 Agent Interaction Flow       "
        );
        console.log(
            "================================================================\n"
        );

        // ============ STEP 1: Agent Registration ============
        console.log("--- STEP 1: Agent Registration ---\n");

        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent("trading.alice.eth", alice);
        console.log("Alice's Trading Agent registered (ID:", aliceAgentId, ")");

        vm.prank(bob);
        bobAgentId = identityRegistry.newAgent("analytics.bob.eth", bob);
        console.log("Bob's Analytics Agent registered (ID:", bobAgentId, ")");

        vm.prank(charlie);
        charlieAgentId = identityRegistry.newAgent(
            "auditor.charlie.eth",
            charlie
        );
        console.log(
            "Charlie's Auditor Agent registered (ID:",
            charlieAgentId,
            ")"
        );

        console.log(
            "\nTotal agents in ecosystem:",
            identityRegistry.getAgentCount()
        );

        // ============ STEP 2: Service Interaction ============
        console.log("\n--- STEP 2: Service Interaction (Off-Chain) ---\n");
        console.log(
            "Alice's agent requests market analysis from Bob's agent..."
        );
        console.log(
            "Bob's agent processes the request and returns analytics..."
        );

        // Simulate: Bob creates hash of the analytics results
        bytes32 analyticsHash = keccak256(
            abi.encodePacked(
                "BTC Analysis: Bullish trend detected",
                "Confidence: 78%",
                "Timestamp: 2026-02-08"
            )
        );
        console.log("Analytics Result Hash:", vm.toString(analyticsHash));

        // ============ STEP 3: Authorize Feedback ============
        console.log("\n--- STEP 3: Authorize Feedback ---\n");

        vm.prank(bob);
        reputationRegistry.acceptFeedback(aliceAgentId, bobAgentId);
        console.log("Bob authorized Alice to provide feedback on his service");

        (bool isAuth, bytes32 authId) = reputationRegistry.isFeedbackAuthorized(
            aliceAgentId,
            bobAgentId
        );
        console.log("Feedback Authorization ID:", vm.toString(authId));
        assertTrue(isAuth);

        // ============ STEP 4: Request Validation ============
        console.log("\n--- STEP 4: Request Independent Validation ---\n");

        validationRegistry.validationRequest(
            charlieAgentId,
            bobAgentId,
            analyticsHash
        );
        console.log("Validation request submitted to Charlie's Auditor Agent");

        (bool reqExists, bool reqPending) = validationRegistry
            .isValidationPending(analyticsHash);
        console.log(
            "Request Status - Exists:",
            reqExists,
            "| Pending:",
            reqPending
        );

        // ============ STEP 5: Validator Responds ============
        console.log("\n--- STEP 5: Validation Response ---\n");
        console.log("Charlie's agent reviews Bob's analytics...");
        console.log("Checking data integrity, methodology, and conclusions...");

        vm.prank(charlie);
        validationRegistry.validationResponse(analyticsHash, 92);

        (bool hasResp, uint8 valScore) = validationRegistry
            .getValidationResponse(analyticsHash);
        console.log("\nValidation Complete!");
        console.log("Score:", valScore, "/ 100");
        console.log("Status: VERIFIED");
        assertTrue(hasResp);
        assertEq(valScore, 92);

        // ============ Summary ============
        console.log(
            "\n================================================================"
        );
        console.log(
            "                    WORKFLOW SUMMARY                            "
        );
        console.log(
            "================================================================"
        );
        console.log("Agents Registered:        3");
        console.log("Feedback Authorized:      Alice -> Bob");
        console.log("Validation Requested:     Bob's work by Charlie");
        console.log("Validation Score:         92/100 (Verified)");
        console.log(
            "================================================================\n"
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //                            ERROR HANDLING DEMOS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice DEMO 11: Error Handling - Duplicate Domain
     * @dev Shows that duplicate domains are rejected
     */
    function test_Demo11_DuplicateDomainReverts() public {
        console.log("\n=== DEMO 11: Error Handling - Duplicate Domain ===\n");

        // Alice registers first
        vm.prank(alice);
        identityRegistry.newAgent("unique-domain.eth", alice);
        console.log("Alice registered: unique-domain.eth");

        // Bob tries to use the same domain
        vm.prank(bob);
        console.log("Bob attempting to register same domain...");

        vm.expectRevert(IIdentityRegistry.DomainAlreadyRegistered.selector);
        identityRegistry.newAgent("unique-domain.eth", bob);

        console.log("Transaction reverted: DomainAlreadyRegistered");
    }

    /**
     * @notice DEMO 12: Error Handling - Unauthorized Update
     * @dev Shows that only the agent owner can update their info
     */
    function test_Demo12_UnauthorizedUpdateReverts() public {
        console.log(
            "\n=== DEMO 12: Error Handling - Unauthorized Update ===\n"
        );

        // Alice registers
        vm.prank(alice);
        aliceAgentId = identityRegistry.newAgent("alice-domain.eth", alice);
        console.log("Alice registered agent ID:", aliceAgentId);

        // Bob tries to update Alice's agent
        vm.prank(bob);
        console.log("Bob (unauthorized) attempting to update Alice's agent...");

        vm.expectRevert(IIdentityRegistry.UnauthorizedUpdate.selector);
        identityRegistry.updateAgent(
            aliceAgentId,
            "hacked-domain.eth",
            address(0)
        );

        console.log("Transaction reverted: UnauthorizedUpdate");
    }

    /**
     * @notice DEMO 13: Error Handling - Unauthorized Validator Response
     * @dev Shows that only the designated validator can respond
     */
    function test_Demo13_UnauthorizedValidatorReverts() public {
        console.log(
            "\n=== DEMO 13: Error Handling - Unauthorized Validator ===\n"
        );

        // Register agents
        vm.prank(bob);
        bobAgentId = identityRegistry.newAgent("bob.eth", bob);

        vm.prank(charlie);
        charlieAgentId = identityRegistry.newAgent("charlie.eth", charlie);

        // Create a validation request with Charlie as validator
        bytes32 dataHash = keccak256("test data");
        validationRegistry.validationRequest(
            charlieAgentId,
            bobAgentId,
            dataHash
        );
        console.log("Validation request created with Charlie as validator");

        // Alice (not the validator) tries to respond
        vm.prank(alice);
        console.log("Alice (not the validator) attempting to respond...");

        vm.expectRevert(IValidationRegistry.UnauthorizedValidator.selector);
        validationRegistry.validationResponse(dataHash, 50);

        console.log("Transaction reverted: UnauthorizedValidator");
    }

    /**
     * @notice DEMO 14: Error Handling - Invalid Validation Response
     * @dev Shows that validation score must be 0-100
     */
    function test_Demo14_InvalidValidationScoreReverts() public {
        console.log(
            "\n=== DEMO 14: Error Handling - Invalid Validation Score ===\n"
        );

        // Register agents and create request
        vm.prank(bob);
        bobAgentId = identityRegistry.newAgent("bob.eth", bob);

        vm.prank(charlie);
        charlieAgentId = identityRegistry.newAgent("charlie.eth", charlie);

        bytes32 dataHash = keccak256("test data");
        validationRegistry.validationRequest(
            charlieAgentId,
            bobAgentId,
            dataHash
        );

        // Charlie tries to respond with invalid score (> 100)
        vm.prank(charlie);
        console.log("Charlie attempting to submit score of 150 (invalid)...");

        vm.expectRevert(IValidationRegistry.InvalidResponse.selector);
        validationRegistry.validationResponse(dataHash, 150);

        console.log(
            "Transaction reverted: InvalidResponse (score must be 0-100)"
        );
    }
}
