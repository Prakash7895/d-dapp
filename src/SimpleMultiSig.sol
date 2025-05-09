// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

enum ProposalStatus {
    INACTIVE,
    ACTIVE,
    EXECUTED
}

contract SimpleMultiSig {
    address public s_owner1;
    address public s_owner2;

    struct Proposal {
        address payable destination;
        uint256 amount;
        mapping(address => bool) approved;
        ProposalStatus status;
    }

    Proposal[] public s_proposals;

    modifier onlyOwner() {
        bool ownerFound = ((msg.sender == s_owner1) ||
            (msg.sender == s_owner2));
        require(ownerFound, "NOT_OWNER");
        _;
    }

    modifier outOfScope(uint256 proposalIdx) {
        require(proposalIdx < s_proposals.length, "OUT_OF_SCOPE");
        _;
    }

    constructor(address _owner1, address _owner2) {
        s_owner1 = _owner1;
        s_owner2 = _owner2;
    }

    function getProposal(
        uint256 index
    )
        public
        view
        returns (address destination, uint256 amount, ProposalStatus status)
    {
        Proposal storage proposal = s_proposals[index];
        return (proposal.destination, proposal.amount, proposal.status);
    }

    function getProposalCount() public view returns (uint256) {
        return s_proposals.length;
    }

    function isApproved(
        uint256 proposalIdx,
        address owner
    ) public view outOfScope(proposalIdx) returns (bool) {
        return s_proposals[proposalIdx].approved[owner];
    }

    function submitProposal(
        address payable _destination,
        uint256 _amount
    ) external onlyOwner {
        require(_amount > 0, "PSOSITIVE_AMOUNT");
        require(_amount <= address(this).balance, "INVALID_AMOUNT");
        Proposal storage newProposal = s_proposals.push();

        newProposal.destination = _destination;
        newProposal.amount = _amount;
        newProposal.approved[msg.sender] = true;
        newProposal.status = ProposalStatus.ACTIVE;
    }

    function approveProposal(
        uint256 proposalIdx
    ) external onlyOwner outOfScope(proposalIdx) {
        Proposal storage proposal = s_proposals[proposalIdx];
        require(proposal.status == ProposalStatus.ACTIVE, "NOT_ACTIVE");

        require(!proposal.approved[msg.sender], "ALREADY_APPROVED");
        proposal.approved[msg.sender] = true;

        if (proposal.approved[s_owner1] && proposal.approved[s_owner2]) {
            (bool success, ) = proposal.destination.call{
                value: proposal.amount
            }("");
            require(success, "TRANSFER_FAILED");
            proposal.status = ProposalStatus.EXECUTED;
        }
    }

    function inactivateProposal(
        uint proposalIdx
    ) external onlyOwner outOfScope(proposalIdx) {
        Proposal storage proposal = s_proposals[proposalIdx];
        require(proposal.status == ProposalStatus.ACTIVE, "NOT_ACTIVE");

        proposal.status = ProposalStatus.INACTIVE;
    }

    receive() external payable {}
}
