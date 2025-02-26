// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

enum ProposalStatus {
    ACTIVE,
    INACTIVE
}

contract SimpleMultiSig {
    address[] public s_owners;
    uint256 public s_requiredApprovals;

    struct Proposal {
        address payable destination;
        uint256 amount;
        uint256 approvals;
        mapping(address => bool) approved;
        bool executed;
        ProposalStatus status;
    }

    Proposal[] public s_proposals;

    modifier onlyOwner() {
        bool ownerFound = false;
        uint256 totalOwners = s_owners.length;
        for (uint256 i = 0; i < totalOwners; i++) {
            if (s_owners[i] == msg.sender) {
                ownerFound = true;
                break;
            }
        }
        require(ownerFound, "Not an owner!");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(
            _owners.length >= _requiredApprovals,
            "Owners less than required Approvals"
        );
        s_owners = _owners;
        s_requiredApprovals = _requiredApprovals;
    }

    function submitProposal(
        address payable _destination,
        uint256 _amount
    ) external onlyOwner {
        require(_amount > 0, "Amount should be greater than 0.");
        Proposal storage newProposal = s_proposals.push();

        newProposal.destination = _destination;
        newProposal.amount = _amount;
        newProposal.approvals = 1;
        newProposal.approved[msg.sender] = true;
        newProposal.executed = false;
        newProposal.status = ProposalStatus.ACTIVE;
    }

    function approveProposal(uint256 proposalIdx) external onlyOwner {
        require(proposalIdx < s_proposals.length, "Index out of scope");

        Proposal storage proposal = s_proposals[proposalIdx];
        require(
            proposal.status == ProposalStatus.ACTIVE,
            "Cant approve inactive proposal"
        );
        require(!proposal.executed, "Already executed!");
        require(!proposal.approved[msg.sender], "Already approved!");
        proposal.approved[msg.sender] = true;
        proposal.approvals += 1;

        if (proposal.approvals >= s_requiredApprovals) {
            executeProposal(proposalIdx);
        }
    }

    function inactivateProposal(uint proposalIdx) external onlyOwner {
        require(proposalIdx < s_proposals.length, "Index out of scope");

        Proposal storage proposal = s_proposals[proposalIdx];
        require(!proposal.executed, "Already executed!");
        proposal.status = ProposalStatus.INACTIVE;
    }

    function executeProposal(uint256 proposalIdx) internal {
        Proposal storage proposal = s_proposals[proposalIdx];
        require(!proposal.executed, "Already executed!");
        require(
            proposal.approvals >= s_requiredApprovals,
            "Not enough approvals!"
        );

        proposal.executed = true;
        (bool success, ) = proposal.destination.call{value: proposal.amount}(
            ""
        );
        require(success, "Transfer Failed!");
    }

    receive() external payable {}
}
