pragma solidity 0.4.23;

import 'mixbytes-solidity/contracts/security/ArgumentsChecker.sol';
import 'zeppelin-solidity/contracts/ReentrancyGuard.sol';
import './EthPriceDependentForICO.sol';
import './crowdsale/FundsRegistry.sol';
import './IBoomstarterToken.sol';
import '../minter-service/contracts/IICOInfo.sol';
import '../minter-service/contracts/IMintableToken.sol';



contract BoomstarterICO is ArgumentsChecker, ReentrancyGuard, EthPriceDependentForICO, IICOInfo, IMintableToken {

    enum IcoState { INIT, ACTIVE, PAUSED, FAILED, SUCCEEDED }

    event StateChanged(IcoState _state);
    event FundTransfer(address backer, uint amount, bool isContribution);


    modifier requiresState(IcoState _state) {
        require(m_state == _state);
        _;
    }






    modifier timedStateChange(address client, uint payment, bool refundable) {
        if (IcoState.INIT == m_state && getTime() >= getStartTime())
            changeState(IcoState.ACTIVE);

        if (IcoState.ACTIVE == m_state && getTime() >= getFinishTime()) {
            finishICO();

            if (refundable && payment > 0)
                client.transfer(payment);

        } else {
            _;
        }
    }





    modifier fundsChecker(address client, uint payment, bool refundable) {
        uint atTheBeginning = m_funds.balance;
        if (atTheBeginning < m_lastFundsAmount) {
            changeState(IcoState.PAUSED);
            if (refundable && payment > 0)
                client.transfer(payment);

        } else {
            _;

            if (m_funds.balance < atTheBeginning) {
                changeState(IcoState.PAUSED);
            } else {
                m_lastFundsAmount = m_funds.balance;
            }
        }
    }

    function estimate(uint256 _wei) public view returns (uint tokens) {
        uint amount;
        (amount, ) = estimateTokensWithActualPayment(_wei);
        return amount;
    }

    function isSaleActive() public view returns (bool active) {
        return m_state == IcoState.ACTIVE && !priceExpired();
    }

    function purchasedTokenBalanceOf(address addr) public view returns (uint256 tokens) {
        return m_token.balanceOf(addr);
    }

    function estimateTokensWithActualPayment(uint256 _payment) public view returns (uint amount, uint actualPayment) {

        uint tokens = _payment.mul(m_ETHPriceInCents).div(getPrice());

        if (tokens.add(m_currentTokensSold) > c_maximumTokensSold) {
            tokens = c_maximumTokensSold.sub( m_currentTokensSold );
            _payment = getPrice().mul(tokens).div(m_ETHPriceInCents);
        }


        if (_payment.mul(m_ETHPriceInCents).div(1 ether) >= 5000000) {
            tokens = tokens.add(tokens.div(5));

            if (tokens.add(m_currentTokensSold) > c_maximumTokensSold) {
                tokens = c_maximumTokensSold.sub(m_currentTokensSold);
            }
        }

        return (tokens, _payment);
    }











    function BoomstarterICO(
        address[] _owners,
        address _token,
        uint _updateInterval,
        bool _production
    )
        public
        payable
        EthPriceDependent(_owners, 2, _production)
        validAddress(_token)
    {
        require(3 == _owners.length);

        m_token = IBoomstarterToken(_token);

        m_deployer = msg.sender;
        m_ETHPriceUpdateInterval = _updateInterval;
    }






    function init(address _funds, address _tokenDistributor, uint _previouslySold)
        external
        validAddress(_funds)
        validAddress(_tokenDistributor)
        onlymanyowners(keccak256(msg.data))
    {

        require(m_funds == address(0));
        m_funds = FundsRegistry(_funds);


        c_maximumTokensSold = m_token.balanceOf(this).sub( m_token.totalSupply().div(4) );


        if (_previouslySold < c_softCapUsd)
            c_softCapUsd = c_softCapUsd.sub(_previouslySold);
        else
            c_softCapUsd = 0;


        m_tokenDistributor = _tokenDistributor;
    }





    function() payable {
        require(0 == msg.data.length);
        buy();
    }


    function buy() public payable {
        internalBuy(msg.sender, msg.value, true);
    }

    function mint(address client, uint256 ethers) public {
        nonEtherBuy(client, ethers);
    }






    function nonEtherBuy(address client, uint etherEquivalentAmount)
        public
    {
        require(msg.sender == m_nonEtherController);

        require(etherEquivalentAmount <= 70000 ether);
        internalBuy(client, etherEquivalentAmount, false);
    }





    function internalBuy(address client, uint payment, bool refundable)
        internal
        nonReentrant
        timedStateChange(client, payment, refundable)
        fundsChecker(client, payment, refundable)
    {


        require( !priceExpired() );


























































































































































































































































































