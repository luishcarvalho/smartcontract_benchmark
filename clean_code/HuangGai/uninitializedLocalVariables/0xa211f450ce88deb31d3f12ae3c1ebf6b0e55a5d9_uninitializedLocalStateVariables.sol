




pragma solidity 0.6.12;














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c ;


        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c ;



        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}






library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}










library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance ;

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance ;

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}





interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ParsiqBoost is IERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant private MAX_UINT256 = ~uint256(0);
    string constant public name = "Parsiq Boost";
    string constant public symbol = "PRQBOOST";
    uint8 constant public decimals = 18;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    mapping(address => uint256) public reviewPeriods;
    mapping(address => uint256) public decisionPeriods;
    uint256 public reviewPeriod ;

    uint256 public decisionPeriod ;

    address public governanceBoard;
    address public pendingGovernanceBoard;
    bool public paused ;


    event Paused();
    event Unpaused();
    event Reviewing(address indexed account, uint256 reviewUntil, uint256 decideUntil);
    event Resolved(address indexed account);
    event ReviewPeriodChanged(uint256 reviewPeriod);
    event DecisionPeriodChanged(uint256 decisionPeriod);
    event GovernanceBoardChanged(address indexed from, address indexed to);
    event GovernedTransfer(address indexed from, address indexed to, uint256 amount);

    modifier whenNotPaused() {
        require(!paused || msg.sender == governanceBoard, "Pausable: paused");
        _;
    }

    modifier onlyGovernanceBoard() {
        require(msg.sender == governanceBoard, "Sender is not governance board");
        _;
    }

    modifier onlyPendingGovernanceBoard() {
        require(msg.sender == pendingGovernanceBoard, "Sender is not the pending governance board");
        _;
    }

    modifier onlyResolved(address account) {
        require(decisionPeriods[account] < block.timestamp, "Account is being reviewed");
        _;
    }

    constructor () public {
        _setGovernanceBoard(msg.sender);
        _totalSupply = 100000000e18;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function pause() public onlyGovernanceBoard {
        require(!paused, "Pausable: paused");
        paused = true;
        emit Paused();
    }

    function unpause() public onlyGovernanceBoard {
        require(paused, "Pausable: unpaused");
        paused = false;
        emit Unpaused();
    }

    function review(address account) public onlyGovernanceBoard {
        _review(account);
    }

    function resolve(address account) public onlyGovernanceBoard {
        _resolve(account);
    }

    function electGovernanceBoard(address newGovernanceBoard) public onlyGovernanceBoard {
        pendingGovernanceBoard = newGovernanceBoard;
    }

    function takeGovernance() public onlyPendingGovernanceBoard {
        _setGovernanceBoard(pendingGovernanceBoard);
        pendingGovernanceBoard = address(0);
    }

    function _setGovernanceBoard(address newGovernanceBoard) internal {
        emit GovernanceBoardChanged(governanceBoard, newGovernanceBoard);
        governanceBoard = newGovernanceBoard;
    }




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public override
        onlyResolved(msg.sender)
        onlyResolved(recipient)
        whenNotPaused
        returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public override
        onlyResolved(msg.sender)
        onlyResolved(spender)
        whenNotPaused
        returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public override
        onlyResolved(msg.sender)
        onlyResolved(sender)
        onlyResolved(recipient)
        whenNotPaused
        returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] < MAX_UINT256) {
            _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }









    function governedTransfer(address from, address to, uint256 value) public onlyGovernanceBoard
        returns (bool) {
        require(block.timestamp >  reviewPeriods[from], "Review period is not elapsed");
        require(block.timestamp <= decisionPeriods[from], "Decision period expired");

        _transfer(from, to, value);
        emit GovernedTransfer(from, to, value);
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public
        onlyResolved(msg.sender)
        onlyResolved(spender)
        whenNotPaused
        returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public
        onlyResolved(msg.sender)
        onlyResolved(spender)
        whenNotPaused
        returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }












    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }






    function burn(uint256 amount) public
        onlyResolved(msg.sender)
        whenNotPaused
    {
        _burn(msg.sender, amount);
    }

    function transferMany(address[] calldata recipients, uint256[] calldata amounts)
        onlyResolved(msg.sender)
        whenNotPaused
        external {
        require(recipients.length == amounts.length, "ParsiqToken: Wrong array length");

        uint256 total ;

        for (uint256 i ; i < amounts.length; i++) {

            total = total.add(amounts[i]);
        }

        _balances[msg.sender] = _balances[msg.sender].sub(total, "ERC20: transfer amount exceeds balance");

        for (uint256 i ; i < recipients.length; i++) {

            address recipient ;

            uint256 amount ;

            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(decisionPeriods[recipient] < block.timestamp, "Account is being reviewed");

            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(msg.sender, recipient, amount);
        }
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {

        require(decisionPeriods[owner] < block.timestamp, "Account is being reviewed");
        require(decisionPeriods[spender] < block.timestamp, "Account is being reviewed");
        require(!paused || msg.sender == governanceBoard, "Pausable: paused");
        require(deadline >= block.timestamp, 'ParsiqToken: EXPIRED');
        bytes32 digest ;


        address recoveredAddress ;


        require(recoveredAddress != address(0) && recoveredAddress == owner, 'ParsiqToken: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function setReviewPeriod(uint256 _reviewPeriod) public onlyGovernanceBoard {
        reviewPeriod = _reviewPeriod;
        emit ReviewPeriodChanged(reviewPeriod);
    }

    function setDecisionPeriod(uint256 _decisionPeriod) public onlyGovernanceBoard {
        decisionPeriod = _decisionPeriod;
        emit DecisionPeriodChanged(decisionPeriod);
    }

    function recoverTokens(IERC20 token, address to, uint256 amount) public onlyGovernanceBoard {
        uint256 balance ;

        require(balance >= amount, "ERC20: Insufficient balance");
        token.safeTransfer(to, amount);
    }

    function _review(address account) internal {
        uint256 reviewUntil ;

        uint256 decideUntil ;

        reviewPeriods[account] = reviewUntil;
        decisionPeriods[account] = decideUntil;
        emit Reviewing(account, reviewUntil, decideUntil);
    }

    function _resolve(address account) internal {
        reviewPeriods[account] = 0;
        decisionPeriods[account] = 0;
        emit Resolved(account);
    }
}
