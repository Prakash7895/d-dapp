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
        require(ownerFound, "Not an owner!");
        _;
    }

    modifier outOfScope(uint256 proposalIdx) {
        require(proposalIdx < s_proposals.length, "Index out of scope");
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
        require(_amount > 0, "Amount should be greater than 0.");
        require(
            _amount <= address(this).balance,
            "Amount exceeds contract balance"
        );
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
        require(
            proposal.status == ProposalStatus.ACTIVE,
            "Can approve only active proposal"
        );

        require(!proposal.approved[msg.sender], "Already approved!");
        proposal.approved[msg.sender] = true;

        if (proposal.approved[s_owner1] && proposal.approved[s_owner2]) {
            (bool success, ) = proposal.destination.call{
                value: proposal.amount
            }("");
            require(success, "Transfer Failed!");
            proposal.status = ProposalStatus.EXECUTED;
        }
    }

    function inactivateProposal(
        uint proposalIdx
    ) external onlyOwner outOfScope(proposalIdx) {
        Proposal storage proposal = s_proposals[proposalIdx];
        require(
            proposal.status == ProposalStatus.ACTIVE,
            "can inactivate only active proposal"
        );

        proposal.status = ProposalStatus.INACTIVE;
    }

    receive() external payable {}
}
