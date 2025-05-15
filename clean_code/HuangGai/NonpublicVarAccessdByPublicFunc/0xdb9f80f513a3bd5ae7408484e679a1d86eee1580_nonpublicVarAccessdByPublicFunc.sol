





pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

interface IComp {
    function delegate(address delegatee) external;
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool);
}

interface IGovernorAlpha {
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) external returns (uint);
    function castVote(uint proposalId, bool support) external;
}

contract CrowdProposal {

    address payable internal immutable author;


    address[] internal targets;
    uint[] internal values;
    string[] internal signatures;
    bytes[] internal calldatas;
    string internal description;


    address internal immutable comp;

    address internal immutable governor;


    uint internal govProposalId;

    bool internal terminated;


    event CrowdProposalProposed(address indexed proposal, address indexed author, uint proposalId);

    event CrowdProposalTerminated(address indexed proposal, address indexed author);

    event CrowdProposalVoted(address indexed proposal, uint proposalId);












    constructor(address payable author_,
                address[] memory targets_,
                uint[] memory values_,
                string[] memory signatures_,
                bytes[] memory calldatas_,
                string memory description_,
                address comp_,
                address governor_) public {
        author = author_;


        targets = targets_;
        values = values_;
        signatures = signatures_;
        calldatas = calldatas_;
        description = description_;


        comp = comp_;
        governor = governor_;

        terminated = false;


        IComp(comp_).delegate(address(this));
    }


    function propose() external returns (uint) {
        require(govProposalId == 0, 'CrowdProposal::propose: gov proposal already exists');
        require(!terminated, 'CrowdProposal::propose: proposal has been terminated');


        govProposalId = IGovernorAlpha(governor).propose(targets, values, signatures, calldatas, description);
        emit CrowdProposalProposed(address(this), author, govProposalId);

        return govProposalId;
    }


    function terminate() external {
        require(msg.sender == author, 'CrowdProposal::terminate: only author can terminate');
        require(!terminated, 'CrowdProposal::terminate: proposal has been already terminated');

        terminated = true;


        IComp(comp).transfer(author, IComp(comp).balanceOf(address(this)));

        emit CrowdProposalTerminated(address(this), author);
    }


    function vote() external {
        require(govProposalId > 0, 'CrowdProposal::vote: gov proposal has not been created yet');
        IGovernorAlpha(governor).castVote(govProposalId, true);

        emit CrowdProposalVoted(address(this), govProposalId);
    }
}
