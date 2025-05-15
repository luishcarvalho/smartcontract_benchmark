

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

interface IERC20 {

    function TOTALSUPPLY191() external view returns (uint256);


    function BALANCEOF259(address account) external view returns (uint256);


    function TRANSFER420(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE902(address owner, address spender) external view returns (uint256);


    function APPROVE574(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM864(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER774(address indexed from, address indexed to, uint256 value);


    event APPROVAL822(address indexed owner, address indexed spender, uint256 value);
}


contract Initializable {


  bool private initialized;


  bool private initializing;


  modifier INITIALIZER61() {
    require(initializing || ISCONSTRUCTOR660() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }


  function ISCONSTRUCTOR660() private view returns (bool) {





    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }


  uint256[50] private ______gap;
}


contract ContextUpgradeable is Initializable {


    function INITIALIZE27() virtual public INITIALIZER61 { }

    function _MSGSENDER667() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA252() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract OwnableUpgradeable is ContextUpgradeable {
    address private _owner;

    event OWNERSHIPTRANSFERRED786(address indexed previousOwner, address indexed newOwner);


    function INITIALIZE27() override virtual public INITIALIZER61 {
        ContextUpgradeable.INITIALIZE27();

        address msgSender = _MSGSENDER667();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED786(address(0), msgSender);
    }


    function OWNER726() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER702() {
        require(_owner == _MSGSENDER667(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP65() public virtual ONLYOWNER702 {
        emit OWNERSHIPTRANSFERRED786(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP548(address newOwner) public virtual ONLYOWNER702 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED786(_owner, newOwner);
        _owner = newOwner;
    }
}


library Account {
    struct Info {
        address owner;
        uint256 number;
    }
}

library Actions {
    enum ActionType {
        Deposit,
        Withdraw,
        Transfer,
        Buy,
        Sell,
        Trade,
        Liquidate,
        Vaporize,
        Call
    }
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}

library Types {
    enum AssetDenomination {
        Wei,
        Par
    }

    enum AssetReference {
        Delta,
        Target
    }

    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Par {
        bool sign;
        uint128 value;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }
}

interface ISoloMargin {
    function OPERATE203(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) external;

    function GETACCOUNTBALANCES476(Account.Info memory account)
        external view
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        );
}

contract dYdXWrapper is OwnableUpgradeable {
    IERC20 public constant dai94 = IERC20(
        0x6B175474E89094C44Da98b954EedeAC495271d0F
    );
    ISoloMargin public constant solomargin196 = ISoloMargin(
        0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e
    );

    function INITIALIZE27() public override INITIALIZER61 {
        OwnableUpgradeable.INITIALIZE27();
        dai94.APPROVE574(address(solomargin196), 100000e18);
    }

    function DEPOSIT959(uint256 value) external ONLYOWNER702 {
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = Account.Info(address(this), 0);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = Actions.ActionArgs(
            Actions.ActionType.Deposit,
            0,
            Types.AssetAmount(
                true,
                Types.AssetDenomination.Wei,
                Types.AssetReference.Delta,
                value
            ),
            3,
            0,
            address(this),
            0,
            bytes("")
        );
        solomargin196.OPERATE203(accounts, actions);
    }

    function WITHDRAW104(uint256 value) external ONLYOWNER702 {
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = Account.Info(address(this), 0);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: value
            }),
            primaryMarketId: 3,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });
        solomargin196.OPERATE203(accounts, actions);
    }

    function ME244() public view returns (address) {
        return address(this);
    }

    function BALANCE490()
        external
        view
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        )
    {
        Account.Info memory account = Account.Info(address(this), 0);
        return solomargin196.GETACCOUNTBALANCES476(account);
    }
}
