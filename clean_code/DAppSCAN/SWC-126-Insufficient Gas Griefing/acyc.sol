




































pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract AllCoinsYieldCapital is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;


    string private _name = "AllCoinsYieldCapital";
    string private _symbol = "ACYC";
    uint8 private _decimals = 18;


    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalTokenSupply = 1 * 10**12 * 10**_decimals;
    uint256 private _totalReflections = (MAX - (MAX % _totalTokenSupply));
    uint256 private _totalTaxesReflectedToHodlers;
    uint256 private _totalTaxesSentToTreasury;
    mapping(address => uint256) private _reflectionsOwned;
    mapping(address => mapping(address => uint256)) private _allowances;


    address payable public _treasuryAddress;
    uint256 private _currentTaxForReflections = 10;
    uint256 private _currentTaxForTreasury = 10;
    uint256 public _fixedTaxForReflections = 10;
    uint256 public _fixedTaxForTreasury = 10;


    mapping(address => bool) private _isExcludedFromTaxes;




    address private uniDefault = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public immutable uniswapV2Router;
    bool private _inSwap = false;
    address public immutable uniswapV2Pair;


    uint256 private _minimumTokensToSwap = 10 * 10**3 * 10**_decimals;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(address payable treasuryAddress, address router) {
        require(
            (treasuryAddress != address(0)),
            "Give me the treasury address"
        );
        _treasuryAddress = treasuryAddress;
        _reflectionsOwned[_msgSender()] = _totalReflections;


        if (router == address(0)) {
            router = uniDefault;
        }
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);


        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
        uniswapV2Router = _uniswapV2Router;


        _isExcludedFromTaxes[owner()] = true;
        _isExcludedFromTaxes[address(this)] = true;
        _isExcludedFromTaxes[_treasuryAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalTokenSupply);
    }


    receive() external payable {
        return;
    }


    function setTreasuryAddress(address payable treasuryAddress) external {
        require(_msgSender() == _treasuryAddress, "You cannot call this");
        require(
            (treasuryAddress != address(0)),
            "Give me the treasury address"
        );
        address _previousTreasuryAddress = _treasuryAddress;
        _treasuryAddress = treasuryAddress;
        _isExcludedFromTaxes[treasuryAddress] = true;
        _isExcludedFromTaxes[_previousTreasuryAddress] = false;
    }


    function excludeFromTaxes(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromTaxes[account] = excluded;
    }


    function setReflectionsTax(uint256 tax) external onlyOwner {

        require(tax >= 0 && tax <= 10, "ERC20: tax out of band");
        _currentTaxForReflections = tax;
        _fixedTaxForReflections = tax;
    }

    function setTreasuryTax(uint256 tax) external onlyOwner {

        require(tax >= 0 && tax <= 10, "ERC20: tax out of band");
        _currentTaxForTreasury = tax;
        _fixedTaxForTreasury = tax;
    }


    function manualSend() external onlyOwner {
        uint256 _contractETHBalance = address(this).balance;
        _sendETHToTreasury(_contractETHBalance);
    }

    function manualSwap() external onlyOwner {
        uint256 _contractBalance = balanceOf(address(this));
        _swapTokensForEth(_contractBalance);
    }



    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        uint256 currentRate = _getRate();
        return _totalReflections.div(currentRate);
    }

    function isExcludedFromTaxes(address account) public view returns (bool) {
        return _isExcludedFromTaxes[account];
    }

    function totalTaxesSentToReflections() public view returns (uint256) {
        return tokensFromReflection(_totalTaxesReflectedToHodlers);
    }

    function totalTaxesSentToTreasury() public view returns (uint256) {
        return tokensFromReflection(_totalTaxesSentToTreasury);
    }

    function getETHBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokensFromReflection(_reflectionsOwned[account]);
    }

    function reflectionFromToken(
        uint256 amountOfTokens,
        bool deductTaxForReflections
    ) public view returns (uint256) {
        require(
            amountOfTokens <= _totalTokenSupply,
            "Amount must be less than supply"
        );
        if (!deductTaxForReflections) {
            (uint256 reflectionsToDebit, , , ) = _getValues(amountOfTokens);
            return reflectionsToDebit;
        } else {
            (, uint256 reflectionsToCredit, , ) = _getValues(amountOfTokens);
            return reflectionsToCredit;
        }
    }

    function tokensFromReflection(uint256 amountOfReflections)
        public
        view
        returns (uint256)
    {
        require(
            amountOfReflections <= _totalReflections,
            "ERC20: Amount too large"
        );
        uint256 currentRate = _getRate();
        return amountOfReflections.div(currentRate);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from 0 address");
        require(spender != address(0), "ERC20: approve to 0 address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }





    function _transfer(
        address sender,
        address recipient,
        uint256 amountOfTokens
    ) private {
        require(sender != address(0), "ERC20: transfer from 0 address");
        require(recipient != address(0), "ERC20: transfer to 0 address");
        require(amountOfTokens > 0, "ERC20: Transfer more than zero");



        bool takeFee = true;
        if (_isExcludedFromTaxes[sender] || _isExcludedFromTaxes[recipient]) {
            takeFee = false;
        }



        bool buySide = false;
        if (sender == address(uniswapV2Pair)) {
            buySide = true;
        }


        if (!takeFee) {
            _setNoFees();
        } else if (buySide) {
            _setBuySideFees();
        } else {
            _setSellSideFees();
        }


        _tokenTransfer(sender, recipient, amountOfTokens);


        _restoreAllFees();
    }


    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amountOfTokens
    ) private {









        if (sender == _treasuryAddress && recipient == address(this)) {
            _manualReflect(amountOfTokens);
            return;
        }



        (
            uint256 reflectionsToDebit,
            uint256 reflectionsToCredit,
            uint256 reflectionsToRemove,
            uint256 reflectionsForTreasury
        ) = _getValues(amountOfTokens);


        _takeTreasuryTax(reflectionsForTreasury);
        _takeReflectionTax(reflectionsToRemove);



        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _minimumTokensToSwap;
        if (!_inSwap && overMinTokenBalance && reflectionsForTreasury != 0) {
            _swapTokensForEth(contractTokenBalance);
        }
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            _sendETHToTreasury(address(this).balance);
        }




        _reflectionsOwned[sender] = _reflectionsOwned[sender].sub(
            reflectionsToDebit
        );
        _reflectionsOwned[recipient] = _reflectionsOwned[recipient].add(
            reflectionsToCredit
        );


        emit Transfer(sender, recipient, reflectionsToCredit.div(_getRate()));
    }



    function _manualReflect(uint256 amountOfTokens) private {
        uint256 currentRate = _getRate();
        uint256 amountOfReflections = amountOfTokens.mul(currentRate);





        _reflectionsOwned[_treasuryAddress] = _reflectionsOwned[
            _treasuryAddress
        ].sub(amountOfReflections);
        _totalReflections = _totalReflections.sub(amountOfReflections);
    }














    function _takeTreasuryTax(uint256 reflectionsForTreasury) private {
        _reflectionsOwned[address(this)] = _reflectionsOwned[address(this)].add(
            reflectionsForTreasury
        );
        _totalTaxesSentToTreasury = _totalTaxesSentToTreasury.add(
            reflectionsForTreasury
        );
    }










    function _takeReflectionTax(uint256 reflectionsToRemove) private {
        _totalReflections = _totalReflections.sub(reflectionsToRemove);
        _totalTaxesReflectedToHodlers = _totalTaxesReflectedToHodlers.add(
            reflectionsToRemove
        );
    }




    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);


        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_treasuryAddress),
            block.timestamp
        );
    }

    function _sendETHToTreasury(uint256 amount) private {
        _treasuryAddress.transfer(amount);
    }



    function _setBuySideFees() private {
        _currentTaxForReflections = _fixedTaxForReflections;
        _currentTaxForTreasury = 0;
    }



    function _setSellSideFees() private {
        _currentTaxForReflections = 0;
        _currentTaxForTreasury = _fixedTaxForTreasury;
    }


    function _setNoFees() private {
        _currentTaxForReflections = 0;
        _currentTaxForTreasury = 0;
    }






    function _restoreAllFees() private {
        _currentTaxForReflections = _fixedTaxForReflections;
        _currentTaxForTreasury = _fixedTaxForTreasury;
    }




    function _getValues(uint256 amountOfTokens)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {


        (
            uint256 tokensToTransfer,
            uint256 tokensForReflections,
            uint256 tokensForTreasury
        ) = _getTokenValues(amountOfTokens);



        uint256 currentRate = _getRate();
        uint256 reflectionsTotal = amountOfTokens.mul(currentRate);
        uint256 reflectionsToTransfer = tokensToTransfer.mul(currentRate);
        uint256 reflectionsToRemove = tokensForReflections.mul(currentRate);
        uint256 reflectionsForTreasury = tokensForTreasury.mul(currentRate);

        return (
            reflectionsTotal,
            reflectionsToTransfer,
            reflectionsToRemove,
            reflectionsForTreasury
        );
    }




    function _getRate() private view returns (uint256) {
        return _totalReflections.div(_totalTokenSupply);
    }






    function _getTokenValues(uint256 amountOfTokens)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tokensForReflections = amountOfTokens
            .mul(_currentTaxForReflections)
            .div(100);
        uint256 tokensForTreasury = amountOfTokens
            .mul(_currentTaxForTreasury)
            .div(100);
        uint256 tokensToTransfer = amountOfTokens.sub(tokensForReflections).sub(
            tokensForTreasury
        );
        return (tokensToTransfer, tokensForReflections, tokensForTreasury);
    }
}
