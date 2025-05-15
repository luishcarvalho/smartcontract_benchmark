
pragma solidity >=0.7.0 <0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";



import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";


import "./IPod.sol";
import "./TokenDrop.sol";
import "./IPodManager.sol";


import "./interfaces/TokenFaucet.sol";
import "./interfaces/IPrizePool.sol";
import "./interfaces/IPrizeStrategyMinimal.sol";







contract Pod is Initializable, ERC20Upgradeable, OwnableUpgradeable, IPod {



    using SafeMath for uint256;




    IERC20Upgradeable public token;
    IERC20Upgradeable public ticket;
    IERC20Upgradeable public pool;


    TokenFaucet public faucet;
    TokenDrop public drop;


    IPrizePool private _prizePool;


    IPodManager public manager;


    address public factory;








    mapping(address => TokenDrop) public drops;







    event Deposited(address user, uint256 amount, uint256 shares);




    event Withdrawl(address user, uint256 amount, uint256 shares);




    event Batch(uint256 amount, uint256 timestamp);




    event Sponsored(address sponsor, uint256 amount);




    event Claimed(address user, uint256 balance);




    event PodClaimed(uint256 amount);




    event ERC20Withdrawn(address target, uint256 tokenId);




    event ERC721Withdrawn(address target, uint256 tokenId);




    event DripCalculate(address account, uint256 amount);




    event ManagementTransferred(
        address indexed previousmanager,
        address indexed newmanager
    );








    modifier onlyManager() {
        require(
            address(manager) == _msgSender(),
            "Manager: caller is not the manager"
        );
        _;
    }




    modifier pauseDepositsDuringAwarding() {
        require(
            !IPrizeStrategyMinimal(_prizePool.prizeStrategy()).isRngRequested(),
            "Cannot deposit while prize is being awarded"
        );
        _;
    }














    function initialize(
        address _prizePoolTarget,
        address _ticket,
        address _pool,
        address _faucet,
        address _manager
    ) external initializer {

        _prizePool = IPrizePool(_prizePoolTarget);


        __ERC20_init_unchained(
            string(
                abi.encodePacked(
                    "Pod ",
                    ERC20Upgradeable(_prizePool.token()).name()
                )
            ),
            string(
                abi.encodePacked(
                    "p",
                    ERC20Upgradeable(_prizePool.token()).symbol()
                )
            )
        );


        __Ownable_init_unchained();


        address[] memory tickets = _prizePool.tokens();


        require(
            address(_ticket) == address(tickets[0]) ||
                address(_ticket) == address(tickets[1]),
            "Pod:initialize-invalid-ticket"
        );


        token = IERC20Upgradeable(_prizePool.token());
        ticket = IERC20Upgradeable(tickets[1]);
        pool = IERC20Upgradeable(_pool);
        faucet = TokenFaucet(_faucet);


        manager = IPodManager(_manager);


        factory = msg.sender;
    }










    function podManager() external view returns (address) {
        return address(manager);
    }






    function setManager(IPodManager newManager)
        public
        virtual
        onlyOwner
        returns (bool)
    {

        require(address(manager) != address(0), "Pod:invalid-manager-address");


        emit ManagementTransferred(address(manager), address(newManager));


        manager = newManager;

        return true;
    }






    function prizePool() external view override returns (address) {
        return address(_prizePool);
    }







    function depositTo(address to, uint256 tokenAmount)
        external
        override
        returns (uint256)
    {
        require(tokenAmount > 0, "Pod:invalid-amount");



        uint256 shares = _deposit(to, tokenAmount);



        IERC20Upgradeable(token).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );


        emit Deposited(to, tokenAmount, shares);


        return shares;
    }







    function withdraw(uint256 shareAmount) external override returns (uint256) {

        require(
            balanceOf(msg.sender) >= shareAmount,
            "Pod:insufficient-shares"
        );


        uint256 tokens = _burnShares(shareAmount);


        emit Withdrawl(msg.sender, tokens, shareAmount);

        return tokens;
    }






    function batch(uint256 batchAmount) external override returns (bool) {
        uint256 tokenBalance = vaultTokenBalance();


        require(tokenBalance > 0, "Pod:zero-float-balance");



        require(batchAmount <= tokenBalance, "Pod:insufficient-float-balance");


        uint256 poolAmount = claimPodPool();


        emit PodClaimed(poolAmount);


        token.approve(address(_prizePool), tokenBalance);


        _prizePool.depositTo(
            address(this),
            batchAmount,
            address(ticket),
            address(this)
        );


        emit Batch(tokenBalance, block.timestamp);

        return true;
    }








    function withdrawERC20(IERC20Upgradeable _target, uint256 amount)
        external
        override
        onlyManager
        returns (bool)
    {

        require(
            address(_target) != address(token) &&
                address(_target) != address(ticket) &&
                address(_target) != address(pool),
            "Pod:invalid-target-token"
        );


        _target.transfer(msg.sender, amount);

        emit ERC20Withdrawn(address(_target), amount);

        return true;
    }











    function withdrawERC721(IERC721 _target, uint256 tokenId)
        external
        override
        onlyManager
        returns (bool)
    {

        _target.transferFrom(address(this), msg.sender, tokenId);


        emit ERC721Withdrawn(address(_target), tokenId);

        return true;
    }








    function claim(address user, address _token)
        external
        override
        returns (uint256)
    {

        require(
            drops[_token] != TokenDrop(address(0)),
            "Pod:invalid-token-drop"
        );


        uint256 _balance = drops[_token].claim(user);

        emit Claimed(user, _balance);

        return _balance;
    }






    function claimPodPool() public returns (uint256) {
        uint256 _claimedAmount = faucet.claim(address(this));


        pool.approve(address(drop), _claimedAmount);


        drop.addAssetToken(_claimedAmount);


        return _claimedAmount;
    }








    function setTokenDrop(address _token, address _tokenDrop)
        external
        returns (bool)
    {
        require(
            msg.sender == factory || msg.sender == owner(),
            "Pod:unauthorized-set-token-drop"
        );


        require(
            drops[_token] == TokenDrop(0),
            "Pod:target-tokendrop-mapping-exists"
        );


        drop = TokenDrop(_tokenDrop);


        drops[_token] = drop;

        return true;
    }











    function _deposit(address user, uint256 amount) internal returns (uint256) {
        uint256 allocation = 0;


        if (totalSupply() == 0) {
            allocation = amount;
        } else {
            allocation = (amount.mul(totalSupply())).div(balance());
        }


        _mint(user, allocation);


        return allocation;
    }






    function _burnShares(uint256 shares) internal returns (uint256) {

        uint256 amount = (balance().mul(shares)).div(totalSupply());


        _burn(msg.sender, shares);


        IERC20Upgradeable _token = IERC20Upgradeable(token);
        uint256 currentBalance = _token.balanceOf(address(this));


        if (amount > currentBalance) {

            uint256 _withdraw = amount.sub(currentBalance);


            uint256 exitFee = _withdrawFromPool(_withdraw);


            amount = amount.sub(exitFee);
        }


        _token.transfer(msg.sender, amount);


        return amount;
    }






    function _withdrawFromPool(uint256 _amount) internal returns (uint256) {
        IPrizePool _pool = IPrizePool(_prizePool);


        (uint256 exitFee, ) =
            _pool.calculateEarlyExitFee(
                address(this),
                address(ticket),
                _amount
            );


        uint256 exitFeePaid =
            _pool.withdrawInstantlyFrom(
                address(this),
                _amount,
                address(ticket),
                exitFee
            );


        return exitFeePaid;
    }









    function getPricePerShare() external view override returns (uint256) {

        if (totalSupply() > 0) {
            return balance().mul(1e18).div(totalSupply());
        } else {
            return 0;
        }
    }





    function getUserPricePerShare(address user)
        external
        view
        returns (uint256)
    {

        if (totalSupply() > 0) {
            return balanceOf(user).mul(1e18).div(balance());
        } else {
            return 0;
        }
    }






    function vaultTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }






    function vaultTicketBalance() public view returns (uint256) {
        return ticket.balanceOf(address(this));
    }






    function vaultPoolBalance() public view returns (uint256) {
        return pool.balanceOf(address(this));
    }






    function balance() public view returns (uint256) {
        return vaultTokenBalance().add(vaultTicketBalance());
    }














    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {

        super._beforeTokenTransfer(from, to, amount);


        drop.beforeTokenTransfer(from, to, address(this));


        emit DripCalculate(from, amount);
    }
}
