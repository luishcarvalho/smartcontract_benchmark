



pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;






contract Ownable {
  address payable public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );






  constructor() public {
    owner = msg.sender;
  }




  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }







  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }





  function transferOwnership(address payable _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }





  function _transferOwnership(address payable _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library ERC20SafeTransfer {
    function safeTransfer(address _tokenAddress, address _to, uint256 _value) internal returns (bool success) {
        (success,) = _tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", _to, _value));
        require(success, "Transfer failed");

        return fetchReturnData();
    }

    function safeTransferFrom(address _tokenAddress, address _from, address _to, uint256 _value) internal returns (bool success) {
        (success,) = _tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value));
        require(success, "Transfer From failed");

        return fetchReturnData();
    }

    function safeApprove(address _tokenAddress, address _spender, uint256 _value) internal returns (bool success) {
        (success,) = _tokenAddress.call(abi.encodeWithSignature("approve(address,uint256)", _spender, _value));
        require(success,  "Approve failed");

        return fetchReturnData();
    }

    function fetchReturnData() internal pure returns (bool success){
        assembly {
            switch returndatasize()
            case 0 {
                success := 1
            }
            case 32 {
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {
                revert(0, 0)
            }
        }
    }

}


contract Withdrawable is Ownable {






    function withdrawToken(address _token, uint256 _amount) public onlyOwner returns (bool) {
        return ERC20SafeTransfer.safeTransfer(_token, owner, _amount);
    }




    function withdrawETH(uint256 _amount) public onlyOwner {
        owner.transfer(_amount);
    }
}





contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool private _paused = false;




  function paused() public view returns (bool) {
    return _paused;
  }




  modifier whenNotPaused() {
    require(!_paused, "Contract is paused.");
    _;
  }




  modifier whenPaused() {
    require(_paused, "Contract not paused.");
    _;
  }




  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused();
  }




  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused();
  }
}





contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function decimals() public view returns (uint256);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}





















contract TokenTransferProxy is Ownable {


    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    }

    modifier targetAuthorized(address target) {
        require(authorized[target]);
        _;
    }

    modifier targetNotAuthorized(address target) {
        require(!authorized[target]);
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

    event LogAuthorizedAddressAdded(address indexed target, address indexed caller);
    event LogAuthorizedAddressRemoved(address indexed target, address indexed caller);







    function addAuthorizedAddress(address target)
        public
        onlyOwner
        targetNotAuthorized(target)
    {
        authorized[target] = true;
        authorities.push(target);
        emit LogAuthorizedAddressAdded(target, msg.sender);
    }



    function removeAuthorizedAddress(address target)
        public
        onlyOwner
        targetAuthorized(target)
    {
        delete authorized[target];
        for (uint i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.length -= 1;
                break;
            }
        }
        emit LogAuthorizedAddressRemoved(target, msg.sender);
    }







    function transferFrom(
        address token,
        address from,
        address to,
        uint value)
        public
        onlyAuthorized
        returns (bool)
    {
        require(ERC20SafeTransfer.safeTransferFrom(token, from, to, value));
        return true;
    }







    function getAuthorizedAddresses()
        public
        view
        returns (address[] memory)
    {
        return authorities;
    }
}





library Utils {

    uint256 constant internal PRECISION = (10**18);
    uint256 constant internal MAX_QTY   = (10**28);
    uint256 constant internal MAX_RATE  = (PRECISION * 10**6);
    uint256 constant internal MAX_DECIMALS = 18;
    uint256 constant internal ETH_DECIMALS = 18;
    uint256 constant internal MAX_UINT = 2**256-1;
    address constant internal ETH_ADDRESS = address(0x0);


    function precision() internal pure returns (uint256) { return PRECISION; }
    function max_qty() internal pure returns (uint256) { return MAX_QTY; }
    function max_rate() internal pure returns (uint256) { return MAX_RATE; }
    function max_decimals() internal pure returns (uint256) { return MAX_DECIMALS; }
    function eth_decimals() internal pure returns (uint256) { return ETH_DECIMALS; }
    function max_uint() internal pure returns (uint256) { return MAX_UINT; }
    function eth_address() internal pure returns (address) { return ETH_ADDRESS; }






    function getDecimals(address token)
        internal
        returns (uint256 decimals)
    {
        bytes4 functionSig = bytes4(keccak256("decimals()"));



        assembly {

            let ptr := mload(0x40)

            mstore(ptr,functionSig)
            let functionSigLength := 0x04
            let wordLength := 0x20

            let success := call(
                                gas,
                                token,
                                0,
                                ptr,
                                functionSigLength,
                                ptr,
                                wordLength
                               )

            switch success
            case 0 {
                decimals := 0
            }
            case 1 {
                decimals := mload(ptr)
            }
            mstore(0x40,add(ptr,0x04))
        }
    }







    function tokenAllowanceAndBalanceSet(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenAmount,
        address addressToAllow
    )
        internal
        view
        returns (bool)
    {
        return (
            ERC20(tokenAddress).allowance(tokenOwner, addressToAllow) >= tokenAmount &&
            ERC20(tokenAddress).balanceOf(tokenOwner) >= tokenAmount
        );
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns (uint) {
        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns (uint) {


        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator;
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal returns (uint) {
        return calcDstQty(srcAmount, getDecimals(address(src)), getDecimals(address(dest)), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal returns (uint) {
        return calcSrcQty(destAmount, getDecimals(address(src)), getDecimals(address(dest)), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns (uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }


    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}





library SafeMath {




  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {



    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }




  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);
    uint256 c = _a / _b;


    return c;
  }




  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }




  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }





  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}






library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {

    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}


contract PartnerRegistry is Ownable, Pausable {

    address target;
    mapping(address => bool) partnerContracts;
    address payable public companyBeneficiary;
    uint256 public basePercentage;
    PartnerRegistry public previousRegistry;

    event PartnerRegistered(address indexed creator, address indexed beneficiary, address partnerContract);

    constructor(PartnerRegistry _previousRegistry, address _target, address payable _companyBeneficiary, uint256 _basePercentage) public {
        previousRegistry = _previousRegistry;
        target = _target;
        companyBeneficiary = _companyBeneficiary;
        basePercentage = _basePercentage;
    }

    function registerPartner(address payable partnerBeneficiary, uint256 partnerPercentage) whenNotPaused public {
        Partner newPartner = Partner(createClone());
        newPartner.init(this,address(0x0000000000000000000000000000000000000000), 0, partnerBeneficiary, partnerPercentage);
        partnerContracts[address(newPartner)] = true;
        emit PartnerRegistered(address(msg.sender), partnerBeneficiary, address(newPartner));
    }

    function overrideRegisterPartner(
        address payable _companyBeneficiary,
        uint256 _companyPercentage,
        address payable partnerBeneficiary,
        uint256 partnerPercentage
    ) public onlyOwner {
        Partner newPartner = Partner(createClone());
        newPartner.init(PartnerRegistry(0x0000000000000000000000000000000000000000), _companyBeneficiary, _companyPercentage, partnerBeneficiary, partnerPercentage);
        partnerContracts[address(newPartner)] = true;
        emit PartnerRegistered(address(msg.sender), partnerBeneficiary, address(newPartner));
    }

    function deletePartner(address _partnerAddress) public onlyOwner {
        partnerContracts[_partnerAddress] = false;
    }

    function createClone() internal returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function isValidPartner(address partnerContract) public view returns(bool) {
        return partnerContracts[partnerContract] || previousRegistry.isValidPartner(partnerContract);
    }

    function updateCompanyInfo(address payable newCompanyBeneficiary, uint256 newBasePercentage) public onlyOwner {
        companyBeneficiary = newCompanyBeneficiary;
        basePercentage = newBasePercentage;
    }
}


contract Partner {

    address payable public partnerBeneficiary;
    uint256 public partnerPercentage;

    uint256 public overrideCompanyPercentage;
    address payable public overrideCompanyBeneficiary;

    PartnerRegistry public registry;

    event LogPayout(
        address[] tokens,
        uint256[] amount
    );

    function init(
        PartnerRegistry _registry,
        address payable _overrideCompanyBeneficiary,
        uint256 _overrideCompanyPercentage,
        address payable _partnerBeneficiary,
        uint256 _partnerPercentage
    ) public {
        require(registry == PartnerRegistry(0x0000000000000000000000000000000000000000) &&
          overrideCompanyBeneficiary == address(0x0) && partnerBeneficiary == address(0x0)
        );
        overrideCompanyBeneficiary = _overrideCompanyBeneficiary;
        overrideCompanyPercentage = _overrideCompanyPercentage;
        partnerBeneficiary = _partnerBeneficiary;
        partnerPercentage = _partnerPercentage;
        overrideCompanyPercentage = _overrideCompanyPercentage;
        registry = _registry;
    }

    function payout(
        address[] memory tokens,
        uint256[] memory amounts
    ) public {
        uint totalFeePercentage = getTotalFeePercentage();
        address payable companyBeneficiary = companyBeneficiary();

        for(uint256 index = 0; index<tokens.length; index++){
            uint256 partnerAmount = SafeMath.div(SafeMath.mul(amounts[index], partnerPercentage), getTotalFeePercentage());
            uint256 companyAmount = amounts[index] - partnerAmount;
            if(tokens[index] == Utils.eth_address()){
                partnerBeneficiary.transfer(partnerAmount);
                companyBeneficiary.transfer(companyAmount);
            } else {
                ERC20SafeTransfer.safeTransfer(tokens[index], partnerBeneficiary, partnerAmount);
                ERC20SafeTransfer.safeTransfer(tokens[index], companyBeneficiary, companyAmount);
            }
        }
	emit LogPayout(tokens,amounts);
    }

    function getTotalFeePercentage() public view returns (uint256){
        return partnerPercentage + companyPercentage();
    }

    function companyPercentage() public view returns (uint256){
        if(registry != PartnerRegistry(0x0000000000000000000000000000000000000000)){
            return Math.max(registry.basePercentage(), partnerPercentage);
        } else {
            return overrideCompanyPercentage;
        }
    }

    function companyBeneficiary() public view returns (address payable) {
        if(registry != PartnerRegistry(0x0000000000000000000000000000000000000000)){
            return registry.companyBeneficiary();
        } else {
            return overrideCompanyBeneficiary;
        }
    }

    function() external payable {

    }
}

library TokenBalanceLibrary {
    struct TokenBalance {
        address tokenAddress;
        uint256 balance;
    }

    function findToken(TokenBalance[20] memory balances, address token)
        internal
        pure
        returns (uint256)
    {
        for (uint256 index = 0; index < balances.length; index++) {
            if (balances[index].tokenAddress == token) {
                return index;
            } else if (
                index != 0 && balances[index].tokenAddress == address(0x0)
            ) {
                balances[index] = TokenBalance(token, 0);
                return index;
            }
        }
    }

    function addBalance(
        TokenBalance[20] memory balances,
        address tokenAddress,
        uint256 amountToAdd
    ) internal pure {
        uint256 tokenIndex = findToken(balances, tokenAddress);
        addBalance(balances, tokenIndex, amountToAdd);
    }

    function addBalance(
        TokenBalance[20] memory balances,
        uint256 balanceIndex,
        uint256 amountToAdd
    ) internal pure {
        balances[balanceIndex].balance += amountToAdd;
    }

    function removeBalance(
        TokenBalance[20] memory balances,
        address tokenAddress,
        uint256 amountToRemove
    ) internal pure {
        uint256 tokenIndex = findToken(balances, tokenAddress);
        removeBalance(balances, tokenIndex, amountToRemove);
    }

    function removeBalance(
        TokenBalance[20] memory balances,
        uint256 balanceIndex,
        uint256 amountToRemove
    ) internal pure {
        balances[balanceIndex].balance -= amountToRemove;
    }
}


contract ExchangeHandler is Withdrawable, Pausable {










    function performOrder(
        bytes memory genericPayload,
        uint256 availableToSpend,
        uint256 targetAmount,
        bool targetAmountIsSource
    )
        public
        payable
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder);

}

interface IGST2 {
    function freeUpTo(uint256) external returns (uint256);
}


contract TotlePrimary is Withdrawable, Pausable {




    IGST2 public constant GAS_TOKEN = IGST2(
        0x0000000000b3F879cb30FE243b4Dfee438691c04
    );
    TokenTransferProxy public tokenTransferProxy;
    mapping(address => bool) public signers;
    uint256 public MIN_REFUND_GAS_PRICE = 3000000000;





    struct Order {
        address payable exchangeHandler;
        bytes encodedPayload;
    }

    struct Trade {
        address sourceToken;
        address destinationToken;
        uint256 amount;
        bool isSourceAmount;
        Order[] orders;
    }

    struct Swap {
        Trade[] trades;
        uint256 minimumExchangeRate;
        uint256 minimumDestinationAmount;
        uint256 sourceAmount;
        uint256 tradeToTakeFeeFrom;
        bool takeFeeFromSource;
        address payable redirectAddress;
        bool required;
    }

    struct SwapCollection {
        Swap[] swaps;
        address payable partnerContract;
        uint256 expirationBlock;
        bytes32 id;
        uint256 maxGasPrice;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct FeeVariables {
        uint256 feePercentage;
        Partner partner;
        uint256 totalFee;
    }

    struct AmountsSpentReceived {
        uint256 spent;
        uint256 received;
    }




    event LogSwapCollection(
        bytes32 indexed id,
        address indexed partnerContract,
        address indexed user
    );

    event LogSwap(
        bytes32 indexed id,
        address sourceAsset,
        address destinationAsset,
        uint256 sourceAmount,
        uint256 destinationAmount,
        address feeAsset,
        uint256 feeAmount
    );




    constructor(address _tokenTransferProxy, address _signer) public {
        tokenTransferProxy = TokenTransferProxy(_tokenTransferProxy);
        signers[_signer] = true;
    }





    modifier notExpired(SwapCollection memory swaps) {
        require(swaps.expirationBlock > block.number, "Expired");
        _;
    }

    modifier validSignature(SwapCollection memory swaps) {
        bytes32 hash = keccak256(
            abi.encode(
                swaps.swaps,
                swaps.partnerContract,
                swaps.expirationBlock,
                swaps.id,
                swaps.maxGasPrice,
                msg.sender
            )
        );
        require(
            signers[ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                swaps.v,
                swaps.r,
                swaps.s
            )],
            "Invalid signature"
        );
        _;
    }

    modifier notAboveMaxGas(SwapCollection memory swaps) {
        require(tx.gasprice <= swaps.maxGasPrice, "Gas price too high");
        _;
    }



    function performSwapCollection(SwapCollection memory swaps)
        public
        payable
        whenNotPaused
        notExpired(swaps)
        validSignature(swaps)
        notAboveMaxGas(swaps)
    {
        uint256 startingGas = 0;
        if (tx.gasprice >= MIN_REFUND_GAS_PRICE) {
            startingGas = gasleft();
        }
        TokenBalanceLibrary.TokenBalance[20] memory balances;
        balances[0] = TokenBalanceLibrary.TokenBalance(
            address(Utils.eth_address()),
            msg.value
        );
        for (
            uint256 swapIndex = 0;
            swapIndex < swaps.swaps.length;
            swapIndex++
        ) {
            performSwap(
                swaps.id,
                swaps.swaps[swapIndex],
                balances,
                swaps.partnerContract
            );
        }
        emit LogSwapCollection(swaps.id, swaps.partnerContract, msg.sender);
        transferAllTokensToUser(balances);
        if (startingGas > 0) {
            refundGas(startingGas);
        }
    }

    function refundGas(uint256 startingGas) internal {
        uint256 gasRemaining = gasleft();
        uint256 gasSpent = startingGas - gasRemaining;
        uint256 tokensToFree = Math.min(
            (gasSpent + 14154) / 41130,
            (gasRemaining - 27710) / (1148 + 5722 + 150)
        );
        GAS_TOKEN.freeUpTo(tokensToFree);
    }

    function addSigner(address newSigner) public onlyOwner {
        signers[newSigner] = true;
    }

    function removeSigner(address signer) public onlyOwner {
        signers[signer] = false;
    }

    function updateMinRefundGasPrice(uint256 newMinRefundGasPrice)
        public
        onlyOwner
    {
        MIN_REFUND_GAS_PRICE = newMinRefundGasPrice;
    }




    function performSwap(
        bytes32 swapCollectionId,
        Swap memory swap,
        TokenBalanceLibrary.TokenBalance[20] memory balances,
        address payable partnerContract
    ) internal {
        if (
            !transferFromSenderDifference(
                balances,
                swap.trades[0].sourceToken,
                swap.sourceAmount
            )
        ) {
            if (swap.required) {
                revert("Failed to get tokens for swap");
            } else {
                return;
            }
        }
        uint256 amountSpentFirstTrade = 0;
        uint256 amountReceived = 0;
        uint256 feeAmount = 0;
        for (
            uint256 tradeIndex = 0;
            tradeIndex < swap.trades.length;
            tradeIndex++
        ) {
            if (
                tradeIndex == swap.tradeToTakeFeeFrom && swap.takeFeeFromSource
            ) {
                feeAmount = takeFee(
                    balances,
                    swap.trades[tradeIndex].sourceToken,
                    partnerContract,
                    tradeIndex == 0 ? swap.sourceAmount : amountReceived
                );
            }
            uint256 tempSpent;
            (tempSpent, amountReceived) = performTrade(
                swap.trades[tradeIndex],
                balances,
                Utils.min(
                    tradeIndex == 0 ? swap.sourceAmount : amountReceived,
                    balances[TokenBalanceLibrary.findToken(
                        balances,
                        swap.trades[tradeIndex].sourceToken
                    )]
                        .balance
                )
            );
            if (
                !swap.trades[tradeIndex].isSourceAmount &&
                amountReceived < swap.trades[tradeIndex].amount
            ) {
                if (swap.required) {
                    revert("Not enough destination amount");
                }
                return;
            }
            if (tradeIndex == 0) {
                amountSpentFirstTrade = tempSpent;
                if (feeAmount != 0) {
                    amountSpentFirstTrade += feeAmount;
                }
            }
            if (
                tradeIndex == swap.tradeToTakeFeeFrom && !swap.takeFeeFromSource
            ) {
                feeAmount = takeFee(
                    balances,
                    swap.trades[tradeIndex].destinationToken,
                    partnerContract,
                    amountReceived
                );
                amountReceived -= feeAmount;
            }
        }
        emit LogSwap(
            swapCollectionId,
            swap.trades[0].sourceToken,
            swap.trades[swap.trades.length - 1].destinationToken,
            amountSpentFirstTrade,
            amountReceived,
            swap.takeFeeFromSource
                ? swap.trades[swap.tradeToTakeFeeFrom].sourceToken
                : swap.trades[swap.tradeToTakeFeeFrom].destinationToken,
            feeAmount
        );

        if (amountReceived < swap.minimumDestinationAmount) {
            revert("Got less than minimumDestinationAmount");
        } else if (
            minimumRateFailed(
                swap.trades[0].sourceToken,
                swap.trades[swap.trades.length - 1].destinationToken,
                swap.sourceAmount,
                amountReceived,
                swap.minimumExchangeRate
            )
        ) {
            revert("Minimum exchange rate not met");
        }
        if (
            swap.redirectAddress != msg.sender &&
            swap.redirectAddress != address(0x0)
        ) {
            uint256 destinationTokenIndex = TokenBalanceLibrary.findToken(
                balances,
                swap.trades[swap.trades.length - 1].destinationToken
            );
            uint256 amountToSend = Math.min(
                amountReceived,
                balances[destinationTokenIndex].balance
            );
            transferTokens(
                balances,
                destinationTokenIndex,
                swap.redirectAddress,
                amountToSend
            );
            TokenBalanceLibrary.removeBalance(
                balances,
                swap.trades[swap.trades.length - 1].destinationToken,
                amountToSend
            );
        }
    }

    function performTrade(
        Trade memory trade,
        TokenBalanceLibrary.TokenBalance[20] memory balances,
        uint256 availableToSpend
    ) internal returns (uint256 totalSpent, uint256 totalReceived) {
        uint256 tempSpent = 0;
        uint256 tempReceived = 0;
        for (
            uint256 orderIndex = 0;
            orderIndex < trade.orders.length;
            orderIndex++
        ) {
            if ((availableToSpend - totalSpent) * 10000 < availableToSpend) {
                break;
            } else if (!trade.isSourceAmount && tempReceived == trade.amount) {
                break;
            } else if (trade.isSourceAmount && tempSpent == trade.amount) {
                break;
            }
            (tempSpent, tempReceived) = performOrder(
                trade.orders[orderIndex],
                availableToSpend - totalSpent,
                trade.isSourceAmount
                    ? availableToSpend - totalSpent
                    : trade.amount - totalReceived,
                trade.isSourceAmount,
                trade.sourceToken,
                balances
            );
            totalSpent += tempSpent;
            totalReceived += tempReceived;
        }
        TokenBalanceLibrary.addBalance(
            balances,
            trade.destinationToken,
            totalReceived
        );
        TokenBalanceLibrary.removeBalance(
            balances,
            trade.sourceToken,
            totalSpent
        );
    }

    function performOrder(
        Order memory order,
        uint256 availableToSpend,
        uint256 targetAmount,
        bool isSourceAmount,
        address tokenToSpend,
        TokenBalanceLibrary.TokenBalance[20] memory balances
    ) internal returns (uint256 spent, uint256 received) {
        if (tokenToSpend == Utils.eth_address()) {
            (spent, received) = ExchangeHandler(order.exchangeHandler)
                .performOrder
                .value(availableToSpend)(
                order.encodedPayload,
                availableToSpend,
                targetAmount,
                isSourceAmount
            );

        } else {
            transferTokens(
                balances,
                TokenBalanceLibrary.findToken(balances, tokenToSpend),
                order.exchangeHandler,
                availableToSpend
            );
            (spent, received) = ExchangeHandler(order.exchangeHandler)
                .performOrder(
                order.encodedPayload,
                availableToSpend,
                targetAmount,
                isSourceAmount
            );
        }
    }

    function minimumRateFailed(
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount,
        uint256 minimumExchangeRate
    ) internal returns (bool failed) {
        uint256 sourceDecimals = sourceToken == Utils.eth_address()
            ? 18
            : Utils.getDecimals(sourceToken);
        uint256 destinationDecimals = destinationToken == Utils.eth_address()
            ? 18
            : Utils.getDecimals(destinationToken);
        uint256 rateGot = Utils.calcRateFromQty(
            sourceAmount,
            destinationAmount,
            sourceDecimals,
            destinationDecimals
        );
        return rateGot < minimumExchangeRate;
    }

    function takeFee(
        TokenBalanceLibrary.TokenBalance[20] memory balances,
        address token,
        address payable partnerContract,
        uint256 amountTraded
    ) internal returns (uint256 feeAmount) {
        Partner partner = Partner(partnerContract);
        uint256 feePercentage = partner.getTotalFeePercentage();
        feeAmount = calculateFee(amountTraded, feePercentage);
        transferTokens(
            balances,
            TokenBalanceLibrary.findToken(balances, token),
            partnerContract,
            feeAmount
        );
        TokenBalanceLibrary.removeBalance(
            balances,
            TokenBalanceLibrary.findToken(balances, token),
            feeAmount
        );
        return feeAmount;
    }

    function transferFromSenderDifference(
        TokenBalanceLibrary.TokenBalance[20] memory balances,
        address token,
        uint256 sourceAmount
    ) internal returns (bool) {
        if (token == Utils.eth_address()) {
            if (sourceAmount > balances[0].balance) {
                return false;
            }
            return true;
        }

        uint256 tokenIndex = TokenBalanceLibrary.findToken(balances, token);
        if (sourceAmount > balances[tokenIndex].balance) {
            bool success;
            (success, ) = address(tokenTransferProxy).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,address,uint256)",
                    token,
                    msg.sender,
                    address(this),
                    sourceAmount - balances[tokenIndex].balance
                )
            );
            if (success) {
                balances[tokenIndex].balance = sourceAmount;
                return true;
            }
            return false;
        }
        return true;
    }

    function transferAllTokensToUser(
        TokenBalanceLibrary.TokenBalance[20] memory balances
    ) internal {
        for (
            uint256 balanceIndex = 0;
            balanceIndex < balances.length;
            balanceIndex++
        ) {
            if (
                balanceIndex != 0 &&
                balances[balanceIndex].tokenAddress == address(0x0)
            ) {
                return;
            }
            transferTokens(
                balances,
                balanceIndex,
                msg.sender,
                balances[balanceIndex].balance
            );
        }
    }

    function transferTokens(
        TokenBalanceLibrary.TokenBalance[20] memory balances,
        uint256 tokenIndex,
        address payable destination,
        uint256 tokenAmount
    ) internal {
        if (tokenAmount > 0) {
            if (balances[tokenIndex].tokenAddress == Utils.eth_address()) {
                destination.transfer(tokenAmount);
            } else {
                require(
                    ERC20SafeTransfer.safeTransfer(
                        balances[tokenIndex].tokenAddress,
                        destination,
                        tokenAmount
                    ),
                    "Transfer failed"
                );
            }
        }
    }




    function calculateFee(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return SafeMath.div(SafeMath.mul(amount, fee), 1 ether);
    }







    function() external payable whenNotPaused {

        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        if (size == 0) {
            revert("EOA cannot send ether to primary fallback");
        }
    }
}
