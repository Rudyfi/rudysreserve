//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;



import "./Core.sol";
import "./Configuration.sol";

contract Governance is Configuration {

  using SafeMath for uint256;

  mapping(address => uint256) public lockedBalance;


  /// @notice Possible states that a proposal may be in
  enum ProposalState { Pending, Active, Defeated, Timelocked, AwaitingExecution, Executed, Expired }

  struct Proposal {
    // Creator of the proposal
    address proposer;
    // target addresses for the call to be made
    address target;
    //transaction data
    bytes transactionData;
    // The block at which voting begins
    uint256 startTime;
    // The block at which voting ends: votes must be cast prior to this block
    uint256 endTime;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Flag marking whether the proposal voting time has been extended
    // Voting time can be extended once, if the proposal outcome has changed during CLOSING_PERIOD
    bool extended;
    // Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;
    // Whether or not the voter supports the proposal
    bool support;
    // The number of votes the voter had, which were cast
    uint256 votes;
  }

  /// @notice The official record of all proposals ever proposed
  Proposal[] public proposals;
  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;
  /// @notice Timestamp when a user can withdraw tokens
  mapping(address => uint256) public canWithdrawAfter;

  IERC20 public theToken;

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 indexed id,
    address indexed proposer,
    address target,
    uint256 startTime,
    uint256 endTime,
    string description,
    bytes transactionData
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  event Voted(uint256 indexed proposalId, address indexed voter, bool indexed support, uint256 votes);

  /// @notice An event emitted when a proposal has been executed
  event ProposalExecuted(uint256 indexed proposalId);

  /// @notice Makes this instance inoperable to prevent selfdestruct attack
  /// Proxy will still be able to properly initialize its storage
  constructor(address _theToken) public {
     theToken = IERC20(_theToken);
    // Create a dummy proposal so that indexes start from 1
    proposals.push(
      Proposal({
        proposer: address(this),
        target: 0x0000000000000000000000000000000000000000,
        transactionData: "",
        startTime: 0,
        endTime: 0,
        forVotes: 0,
        againstVotes: 0,
        executed: true,
        extended: false
      })
    );
    
    _initializeConfiguration();

  }




  function lock(uint256 amount) external {
    _transferTokens(msg.sender, amount);
  }

  function unlock(uint256 amount) external {
    require(getBlockTimestamp() > canWithdrawAfter[msg.sender], "Governance: tokens are locked");
    lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(amount, "Governance: insufficient balance");
    require(theToken.transfer(msg.sender, amount), "theToken: transfer failed");
  }

  function propose(address target, string memory description, bytes calldata transactionData) external returns (uint256) {
    return _propose(msg.sender, target, description, transactionData);
  }

  /**
   * @notice Propose implementation
   * @param proposer proposer address
   * @param target smart contact address that will be executed as result of voting
   * @param description description of the proposal
   * @return the new proposal id
   */
  function _propose(
    address proposer,
    address target,
    string memory description,
    bytes calldata transactionData
  ) internal returns (uint256) {
    uint256 votingPower = lockedBalance[proposer];
    require(votingPower >= PROPOSAL_THRESHOLD, "Governance::propose: proposer votes below proposal threshold");
    // target should be a contract
    require(Address.isContract(target), "Governance::propose: not a contract");

    uint256 latestProposalId = latestProposalIds[proposer];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(
        proposersLatestProposalState != ProposalState.Active && proposersLatestProposalState != ProposalState.Pending,
        "Governance::propose: one live proposal per proposer, found an already active proposal"
      );
    }

    uint256 startTime = getBlockTimestamp().add(VOTING_DELAY);
    uint256 endTime = startTime.add(VOTING_PERIOD);

    Proposal memory newProposal = Proposal({
      proposer: proposer,
      target: target,
      transactionData: transactionData,
      startTime: startTime,
      endTime: endTime,
      forVotes: 0,
      againstVotes: 0,
      executed: false,
      extended: false
    });

    proposals.push(newProposal);
    uint256 proposalId = proposalCount();
    latestProposalIds[newProposal.proposer] = proposalId;

    _lockTokens(proposer, endTime.add(VOTE_EXTEND_TIME).add(EXECUTION_EXPIRATION).add(EXECUTION_DELAY));
    emit ProposalCreated(proposalId, proposer, target, startTime, endTime, description, transactionData);
    return proposalId;
  }

  function execute(uint256 proposalId) external virtual payable {
    require(state(proposalId) == ProposalState.AwaitingExecution, "Governance::execute: invalid proposal state");
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;

    address target = proposal.target;
    require(Address.isContract(target), "Governance::execute: not a contract");


    (bool success, ) = target.call{value: msg.value}(proposal.transactionData);
    require(success,"big fuckup");

    emit ProposalExecuted(proposalId);
  }

  function castVote(uint256 proposalId, bool support) external {
    _castVote(msg.sender, proposalId, support);
  }

  function _castVote(
    address voter,
    uint256 proposalId,
    bool support
  ) internal  {
    require(state(proposalId) == ProposalState.Active, "Governance::_castVote: voting is closed");
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[voter];
    bool beforeVotingState = proposal.forVotes <= proposal.againstVotes;
    uint256 votes = lockedBalance[voter];
    require(votes > 0, "Governance: balance is 0");
    if (receipt.hasVoted) {
      if (receipt.support) {
        proposal.forVotes = proposal.forVotes.sub(receipt.votes);
      } else {
        proposal.againstVotes = proposal.againstVotes.sub(receipt.votes);
      }
    }

    if (support) {
      proposal.forVotes = proposal.forVotes.add(votes);
    } else {
      proposal.againstVotes = proposal.againstVotes.add(votes);
    }

    if (!proposal.extended && proposal.endTime.sub(getBlockTimestamp()) < CLOSING_PERIOD) {
      bool afterVotingState = proposal.forVotes <= proposal.againstVotes;
      if (beforeVotingState != afterVotingState) {
        proposal.extended = true;
        proposal.endTime = proposal.endTime.add(VOTE_EXTEND_TIME);
      }
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;
    _lockTokens(voter, proposal.endTime.add(VOTE_EXTEND_TIME).add(EXECUTION_EXPIRATION).add(EXECUTION_DELAY));
    emit Voted(proposalId, voter, support, votes);
  }

  function _lockTokens(address owner, uint256 timestamp) internal {
    if (timestamp > canWithdrawAfter[owner]) {
      canWithdrawAfter[owner] = timestamp;
    }
  }

  function _transferTokens(address owner, uint256 amount) internal {
    require(theToken.transferFrom(owner, address(this), amount), "theToken: transferFrom failed");
    lockedBalance[owner] = lockedBalance[owner].add(amount);
  }

  function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
    return proposals[proposalId].receipts[voter];
  }

  function state(uint256 proposalId) public view returns (ProposalState) {
    require(proposalId <= proposalCount() && proposalId > 0, "Governance::state: invalid proposal id");
    Proposal storage proposal = proposals[proposalId];
    if (getBlockTimestamp() <= proposal.startTime) {
      return ProposalState.Pending;
    } else if (getBlockTimestamp() <= proposal.endTime) {
      return ProposalState.Active;
    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes + proposal.againstVotes < QUORUM_VOTES) {
      return ProposalState.Defeated;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (getBlockTimestamp() >= proposal.endTime.add(EXECUTION_DELAY).add(EXECUTION_EXPIRATION)) {
      return ProposalState.Expired;
    } else if (getBlockTimestamp() >= proposal.endTime.add(EXECUTION_DELAY)) {
      return ProposalState.AwaitingExecution;
    } else {
      return ProposalState.Timelocked;
    }
  }

  function proposalCount() public view returns (uint256) {
    return proposals.length - 1;
  }

  function getBlockTimestamp() internal virtual view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}
