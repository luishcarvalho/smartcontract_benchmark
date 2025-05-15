


















pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;


interface IUni {
    function delegate(address delegatee) external;
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool);
}

interface IGovernorAlpha {
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) external returns (uint);
    function castVote(uint proposalId, bool support) external;
}

contract AutonomousSway {

    bool public immutable sway = false;


    address payable public immutable author;


    address[] public targets;
    uint[] public values;
    string[] public signatures;
    bytes[] public calldatas;
    string public description;


    address public immutable uni;

    address public immutable governor;


    uint public govProposalId;

    bool public terminated;


    event CrowdProposalProposed(address indexed proposal, address indexed author, uint proposalId);

    event CrowdProposalTerminated(address indexed proposal, address indexed author);

    event CrowdProposalVoted(address indexed proposal, uint proposalId);












    constructor(address payable author_,
                address[] memory targets_,
                uint[] memory values_,
                string[] memory signatures_,
                bytes[] memory calldatas_,
                string memory description_,
                address uni_,
                address governor_) public {
                    author = author_;


                    targets = targets_;
                    values = values_;
                    signatures = signatures_;
                    calldatas = calldatas_;
                    description = description_;


                    uni = uni_;
                    governor = governor_;

                    terminated = false;


                    IUni(uni_).delegate(address(this));
                }


                function propose() external returns (uint) {
                    require(address(this).balance == 0, 'CrowdProposal::propose: gov proposal already exists');
                    require(!terminated, 'CrowdProposal::propose: proposal has been terminated');


                    govProposalId = IGovernorAlpha(governor).propose(targets, values, signatures, calldatas, description);
                    emit CrowdProposalProposed(address(this), author, govProposalId);

                    return govProposalId;
                }


                function terminate() external {
                    require(msg.sender == author, 'CrowdProposal::terminate: only author can terminate');
                    require(!terminated, 'CrowdProposal::terminate: proposal has been already terminated');

                    terminated = true;


                    IUni(uni).transfer(author, IUni(uni).balanceOf(address(this)));

                    emit CrowdProposalTerminated(address(this), author);
                }


                function vote() external returns (bool) {
                    require(govProposalId > 0, 'CrowdProposal::vote: gov proposal has not been created yet');
                    IGovernorAlpha(governor).castVote(govProposalId, sway);

                    emit CrowdProposalVoted(address(this), govProposalId);
                }
}

contract AutonomousSwayFactory {

    address public immutable uni;

    address public immutable governor;

    uint public immutable uniStakeAmount;


    event CrowdProposalCreated(address indexed proposal, address indexed author, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, string description);







    constructor(address uni_,
                address governor_,
                uint uniStakeAmount_) public {
                    uni = uni_;
                    governor = governor_;
                    uniStakeAmount = uniStakeAmount_;
                }










                function createCrowdProposal(address[] memory targets,
                                             uint[] memory values,
                                             string[] memory signatures,
                                             bytes[] memory calldatas,
                                             string memory description) external {

                                                 AutonomousSway proposal = new AutonomousSway(msg.sender, targets, values, signatures, calldatas, description, uni, governor);
                                                 emit CrowdProposalCreated(address(proposal), msg.sender, targets, values, signatures, calldatas, description);


                                                 IUni(uni).transferFrom(msg.sender, address(proposal), uniStakeAmount);
                                             }


}
