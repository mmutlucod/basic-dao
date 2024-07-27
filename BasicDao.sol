// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract AdvancedDAO {
    struct Proposal {
        uint id;
        string description;
        uint voteCountYes;
        uint voteCountNo;
        uint deadline;
        bool executed;
    }

    struct Member {
        bool isMember;
        uint weight;
    }

    mapping(address => Member) public members;
    mapping(uint => Proposal) public proposals;
    uint public nextProposalId;
    uint public membershipFee = 1 ether;
    uint public totalMembers;
    address public owner;

    event MemberJoined(address member);
    event ProposalCreated(uint id, string description, uint deadline);
    event Voted(uint proposalId, address voter, bool support);
    event ProposalExecuted(uint proposalId, bool passed);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Only members can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function joinDAO() external payable {
        require(msg.value == membershipFee, "Incorrect membership fee.");
        require(!members[msg.sender].isMember, "Already a member.");
        members[msg.sender] = Member(true, 1);
        totalMembers++;
        emit MemberJoined(msg.sender);
    }

    function createProposal(string calldata description, uint duration) external onlyMember {
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            description: description,
            voteCountYes: 0,
            voteCountNo: 0,
            deadline: block.timestamp + duration,
            executed: false
        });
        emit ProposalCreated(nextProposalId, description, block.timestamp + duration);
        nextProposalId++;
    }

    function vote(uint proposalId, bool support) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended.");
        require(!proposal.executed, "Proposal has already been executed.");

        if (support) {
            proposal.voteCountYes += members[msg.sender].weight;
        } else {
            proposal.voteCountNo += members[msg.sender].weight;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function executeProposal(uint proposalId) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period has not ended yet.");
        require(!proposal.executed, "Proposal has already been executed.");

        proposal.executed = true;
        bool passed = proposal.voteCountYes > proposal.voteCountNo;

        emit ProposalExecuted(proposalId, passed);
    }

    function increaseMembershipWeight(address member, uint amount) external onlyOwner {
        require(members[member].isMember, "Not a member.");
        members[member].weight += amount;
    }

    function decreaseMembershipWeight(address member, uint amount) external onlyOwner {
        require(members[member].isMember, "Not a member.");
        require(members[member].weight >= amount, "Insufficient weight.");
        members[member].weight -= amount;
    }
}
