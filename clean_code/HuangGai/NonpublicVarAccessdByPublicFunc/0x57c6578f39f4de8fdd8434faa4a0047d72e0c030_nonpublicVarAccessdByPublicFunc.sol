





pragma solidity ^0.6.12;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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




    event burnTotalSupply(uint256 value);
}















library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


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



























contract HopiumCoinContract is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _threshold;
    uint256 private _burnRate;










    constructor () public {
        _name = "HOPIUM";
        _symbol = "HOPIUM";
        _decimals = 18;
        _burnRate = 69;
        _threshold = 2420E18;


        _mint(0x03E1Fe6B95BEFBC99835C6313d01d3075a81BbE2, 45E18);
        _mint(0x05BaD2724b1415a8B6B3000a30E37d9C637D7340, 45E18);
        _mint(0x076C48C9Ef4C50D84C689526d086bA56270e406c, 45E18);
        _mint(0x08103E240B6bE73e29319d9B9DBe9268e32a0b02, 1430E16);
        _mint(0x09b9A7f1335042fAf506ab5c89ce91436B39B46a, 856E16);
        _mint(0x0aA3ae4aB9854903482dA1F78F1052D6BcA64BbE, 3669E16);
        _mint(0x0B11FB8E5072A0C48cf90cDbcFc117776a73605D, 45E18);
        _mint(0x0c6d54839de473480Fe24eC82e4Da65267C6be46, 45E18);
        _mint(0x0C780749E6d0bE3C64c130450B20C40b843fbEC4, 45E18);
        _mint(0x10C223dFB77F49d7Cf95Cc044C2A2216b1253211, 45E18);
        _mint(0x167bB613c031cB387c997c82c02B106939Fd8F07, 45E18);
        _mint(0x16D972690c16EA81CBcef3682d9B46D0Ac0a1FE7, 5747E16);
        _mint(0x1aa0b915BEeA961e6c09121Bb5f9ED98a10b7658, 45E18);
        _mint(0x1D40FC9456A1E6F13f69615FEe1cbcBe604B9167, 1788E16);
        _mint(0x1EBB9eE2b0cd222877e4BcA8a56d4444EfC5e28B, 7966E16);
        _mint(0x2041Ea0efD9702b1Ca13C0FCa2899Ed31B9167dB, 45E18);
        _mint(0x25052177670Dc586FCEF615b35150CE0f0bf88a4, 5467E16);
        _mint(0x26c6f93451BCf317a1FC24393fE760cF695525b3, 1320E16);
        _mint(0x27fa60d49C82379373a76A858742D72D154e96B2, 45E18);
        _mint(0x298c80FCaB43fA9eE0a1EF8E6abF86374e0498d9, 45E18);
        _mint(0x29D62e1d0975bb024B2C40Ef6C878bF809245e71, 104E16);
        _mint(0x2B3352e94EB8bCC46391d89ec7A8C30D352027f8, 3462E16);
        _mint(0x2f442C704c3D4Bd081531175Ce05C2C88603ce09, 45E18);
        _mint(0x3111413a49f62be9b9547620E660780a1AC9bae1, 45E18);
        _mint(0x3293A92372Ae49390a97e1bB3B185EbC30e68870, 20E18);
        _mint(0x3481fBA85c1b227Cd401d4ef2e2390f505738B08, 45E18);
        _mint(0x34b7339C3D515b4a82eE58a6C6884A1f2B429872, 45E18);
        _mint(0x34Ba737f5195e354047a68f1eb42073AF41b153F, 348E18);
        _mint(0x3aDbDCe09f514283FEf7b4dEd6514f2b4A08853a, 1340E16);
        _mint(0x3Cc729E9CD6521E3e97CfFc17a60005f1e78e5Ac, 479E17);
        _mint(0x4342e82B94b128fcCBe1bDDF454e51336cC5fde2, 45E18);
        _mint(0x436b72cd2bc5812B8D9e6e5bD450613f7E2cB70b, 496E16);
        _mint(0x43B4D03a347dAE1753197Cac0FB15333126B271F, 638E16);
        _mint(0x444FE3e5A882D24166Fd64c9598FEcc1702D47e7, 17E18);
        _mint(0x4Ac70381F04eA4A14EE3Dc8142d19D22A116CA52, 755E16);
        _mint(0x4B424674eA391E5Ee53925DBAbD73027D06699A9, 2499E16);
        _mint(0x4E7e1C73C116649c1C684acB6ec98bAc4FbB4ef6, 5973E16);
        _mint(0x4f70eD6b19cc733D5C45A40250227C0c020Ab3cD, 494E16);
        _mint(0x5193542bDEdb3D029c7b399Dbe3b9E40D97A72d3, 2066E16);
        _mint(0x51Ed1e5560a6f60de3b1388e52e93BF9A2BE293A, 823E16);
        _mint(0x529771885770a756eaAb634F68B61495687D3156, 280E16);
        _mint(0x53848cd0F32680E0B253a4164a5E0c552d27Ce36, 574E16);
        _mint(0x5b6136F5C4e2D1b57A2C08527316bFD079F78837, 766E16);
        _mint(0x5c43F73f8E453220Fc946166c2D63f5266fCa9Ff, 167E16);
        _mint(0x5e627786B83397BECCe5Ed74FEB825fed3ad3676, 1068E16);
        _mint(0x6464C890f20BCB6BB54cB762E9c12F1e3e380d46, 1E18);
        _mint(0x652df8A98005416a7e32eea90a86e02a0F33F92e, 45E18);
        _mint(0x6536E7a30d5a912E422e464fC790fec22C86ef14, 2871E16);
        _mint(0x662F6ef2092c126b6EE0Da44e6B863f30971880d, 45E18);
        _mint(0x6986f4FD0290bd948411c15EcC3B0745d83c62F4, 958E16);
        _mint(0x6eFB598D2FfDA3AEF73Ee71a3aeEBaCD6762eE35, 719E16);
        _mint(0x7914254AD6b6c6dBcbDcC4c964Ecda52DCe588a7, 45E18);
        _mint(0x7db6BB068FD59721E856e32166d2F417B4C8543A, 3061E16);
        _mint(0x7e29D5D22F727381358B6B10b6828094CFa93702, 3551E16);
        _mint(0x7e319b0140091625786c4Bedd74dAa68df243c82, 45E18);
        _mint(0x7eB24d86E62BA34134fE5ffaE09bbdcaD7Aff010, 810E16);
        _mint(0x88Eb97E5ECbf1c5b4ecA19aCF659d4724392eD86, 45E18);
        _mint(0x8B2784921F4935aD19F59273962A824f2550ccA7, 421E16);
        _mint(0x8eC686860fe3196667E878ed1D5497EB7fd35872, 23E18);
        _mint(0x8F18fc10277A2d0DdE935A40386fFE30B9A5BC17, 45E18);
        _mint(0x907b4128FF43eD92b14b8145a01e8f9bC6890E3E, 45E18);
        _mint(0x9325901B103A5AeCC699b087fa9D8F4596C27e9E, 3548E16);
        _mint(0x945f48ab557d96d8ed9be43Ca15e9a9497ACa25b, 1609E16);
        _mint(0x946a58054fadF84018CA798BDDAD14EBbA0A042D, 1362E16);
        _mint(0x9725548D0aa23320F1004F573086D1F4cba0804c, 300E18);
        _mint(0x99685f834B99b3c6F3e910c8454eC64101f02296, 45E18);
        _mint(0xa4BD82608192EDdF2A587215085786D1630085E8, 25E18);

        _mint(0xAB00Bf9544f10EF2cF7e8C24E845ae6B62dcd413, 45E18);
        _mint(0xac25C07464c0A53ebA6450c945f62dD66Cf5c1A7, 45E18);
        _mint(0xADB637a329d951D8c8c4E86FD8d4ca308C9d6892, 2E18);
        _mint(0xb1776C152080228214c2E84e39A93311fF3c03C1, 45E18);
        _mint(0xB4Cf7d78Ee8b63C73D7E2a8e7556528cD402FEBA, 4085E16);
        _mint(0xB8B0c4B8877171bfE2D1380bb021c27A274cBB9d, 192E16);
        _mint(0xBa03EcA6b692532648c4da21840fB9Af578147A2, 5754E16);
        _mint(0xbb257625458a12374daf2AD0c91d5A215732F206, 45E18);
        _mint(0xbC17e8Ee00939111E5c74E17f205Dc2805298ff9, 10E18);
        _mint(0xC0Bc8226527038F95d0b02b3Fa7Cfd0D2F344968, 45E18);
        _mint(0xc346D86B69ab3F3f8415b87493E75179FC4997B5, 471E18);
        _mint(0xC419528eDA383691e1aA13C381D977343CB9E5D0, 3093E17);
        _mint(0xc76bf7e1a02a7fe636F1698ba5F4e28e88E3Af3c, 45E18);
        _mint(0xcb794D53530BEE50ba48C539fbc8C5689Ffae34F, 45E18);
        _mint(0xd00c8e3A99aE3C87657ed12005598855DC59f433, 45E18);
        _mint(0xd03A083589edC2aCcf09593951dCf000475cc9f2, 45E18);
        _mint(0xd62a38Bd99376013D485214CC968322C20A6cC40, 45E18);
        _mint(0xD86e5a51a1f062c534cd9A7B9c978b16c40A802A, 45E18);
        _mint(0xd92F8e487bb5a0b6d06Bc59e793cDf9740cdF019, 969E16);
        _mint(0xDA2B7416aCcb991a6391f34341ebe8735E17Ea0e, 45E18);
        _mint(0xDDD890078d116325aEB2a4fA42ED7a0Dd4C1f1Ab, 819E16);
        _mint(0xdF1cb2e9B48C830154CE6030FFc5E2ce7fD6c328, 45E18);
        _mint(0xDFA7C075D408D7BFfBe8691c025Ca33271b2eCCc, 45E18);
        _mint(0xE13C6dC69B7ff1A7BA08A9dC2DD2Ac219A34133E, 1E16);
        _mint(0xe3960cCF27aD7AB88999E645b14939a01C88C5b7, 672E16);
        _mint(0xE58Ea0ceD4417f0551Fb82ddF4F6477072DFb430, 45E18);
        _mint(0xe63ceB167c42AB666270594057d7006D9D145eD5, 3434E16);
        _mint(0xe8e749a426A030D291b96886AEFf644B4ccea67B, 45E18);
        _mint(0xE94D448083dFd5FEafb629Ff1d546aE2BD189783, 168E17);

        _mint(0xE9919D66314255A97d9F53e70Bf28075E65535B4, 45E18);
        _mint(0xeA5DcA8cAc9c12Df3AB5908A106c15ff024CB44F, 118E17);
        _mint(0xea90c80638843767d680040DceCfa4c3ab1573a7, 913E16);
        _mint(0xEAB8712536dc87359B63f101c404cf79983dB97E, 2802E16);
        _mint(0xEF572FbBdB552A00bdc2a3E3Bc9306df9E9e169d, 45E18);
        _mint(0xEfF529448A3969c043C8D46CE65E468e9Db58349, 678E16);
        _mint(0xf0F0fC23cda483D7f7CA11B9cecE8Af20BF0Bd20, 4335E16);
        _mint(0xf1a72A1B1571402e1071BFBfbBa481a50Fb65885, 45E18);
        _mint(0xf422c173264dCd512E3CEE0DB4AcB568707C0b8D, 45E18);
        _mint(0xf5f737C6B321126723BF0afe38818ac46411b5D9, 45E18);
        _mint(0xF874a182b8Cbf5BA2d6F65A21BC9e8368C8C5B07, 45E18);
        _mint(0xf916D5D0310BFCD0D9B8c43D0a29070670D825f9, 45E18);
        _mint(0xfAcb29bE46ccA69Dcb40806eCf2E4C0Bb300ba73, 45E18);
        _mint(0xFdc91e7fD18E08DF7FF183d976F1ba195Ae29860, 995E16);

        _mint(0x7071f8D9bF33E469744d8C6BCc596f5937f5a43F, 3564E18);

        _mint(0x0B11FB8E5072A0C48cf90cDbcFc117776a73605D, 45E18);
        _mint(0xbC17e8Ee00939111E5c74E17f205Dc2805298ff9, 45E18);
        _mint(0x5558647B57C6BE0Cd4a08fe2725965f1d9237AE7, 90E18);
        _mint(0x96693870AAf7608D5D41AE41d839becF781e22b0, 90E18);
        _mint(0x99ee03Aef7a668b7dA6c9e6A33E0CC4a413617C8, 90E18);
        _mint(0x9Aa91482E4D774aeB685b0A87629217257e3ad65, 90E18);
        _mint(0xbccea8a2e82cc2A0f89a4EE559c7d7e1de11eb8e, 45E18);
        _mint(0xDDFB4C1841d57C9aCAe1dC1D1c8C1EAecc1568FC, 45E18);
        _mint(0xe24C2133714B735f7dFf541d4Fb9a101C9aBcb40, 45E18);
        _mint(0x8F6485F44c56E9a8f496e1589D27Bc8256233E0D, 90E18);
        _mint(0x9b0726e95e72eB6f305b472828b88D2d2bDD41C7, 45E18);
        _mint(0x5e336019A05BCF2403430aD0bd76186F43d65F8f, 45E18);
        _mint(0x8D1CE473bb171A9b2Cf2285626f7FB552320ef4D, 90E18);
        _mint(0x9aD70D7aA72Fca9DBeDed92e125526B505fB9E59, 45E18);
        _mint(0x1c41984b9572C54207C4b9D212A815EF9e2eE9a9, 45E18);
        _mint(0xb5ac8804acdd56905c83CA4Ed752788155E2296e, 45E18);
        _mint(0xEf7d508fCFB61187D8d8A48cC6CB187722633E2D, 45E18);
        _mint(0xCc2e32ca9BEea92E4Bbd5777A30D1fB922CfA0F6, 45E18);
        _mint(0xB163870edc9d1a1681F6c88b68fca770A23fB484, 90E18);
        _mint(0x94f490Cc1e2F47393676B5518cc5e29785DcE5CA, 90E18);
        _mint(0xC0a0ADD83f96f455f726D2734f2A87616810c04B, 45E18);
        _mint(0x40feBfC8cC40712937021d117a5fD299C44DD09D, 45E18);
        _mint(0xc7861b59e2193424AfC83a83bD65c8B5216c7EB0, 45E18);
        _mint(0xEF572FbBdB552A00bdc2a3E3Bc9306df9E9e169d, 45E18);
        _mint(0x17BD48111d066870FABBbF341E1f844feA705822, 90E18);
        _mint(0xac6C371aD7015D1653CAda1B39824849884824D4, 45E18);
        _mint(0x957982B268A15ad3Fe3a4f45DaF74BD730EA8522, 90E18);
        _mint(0xac6C371aD7015D1653CAda1B39824849884824D4, 45E18);
        _mint(0x957982B268A15ad3Fe3a4f45DaF74BD730EA8522, 90E18);
        _mint(0xbACf9C6afbF0377467679746fac0BC82Ebc55c13, 90E18);
        _mint(0x374de73Bb1C65dA4Ea256EAFdcD5671747bEa22b, 45E18);
        _mint(0xb6eC0d0172BC4Cff8fF669b543e03c2c8B64Fc5E, 45E18);
        _mint(0x4Ca0201f99b59fdE76b8Df81c2dF83B356d4e02E, 45E18);
        _mint(0xd41c0982bc3fC6dfE763B044808126529c4513c6, 81E18);
        _mint(0x47262B32A23B902A5083B3be5e6A270A71bE83E0, 45E18);
        _mint(0x97D3F96c89eEF4De83c336b8715f78F45CA32411, 45E18);
        _mint(0xCB98923e740db68A341C5C30f375A34352272321, 45E18);
        _mint(0xC0A564ae0BfBFB5c0d2027559669a785916387a6, 45E18);
        _mint(0xD1FDB36024ACa892DAa711fc97a0373Bf918AC7E, 90E18);
        _mint(0x164d53A734F68f2832721c0F1ca859c062C0909F, 45E18);
        _mint(0xF4314E597fC3B53d5bEf1D5362D327c00388A64F, 45E18);
        _mint(0x83A9B9cF068C4F6a47BbD372C5E915350DFc88F7, 45E18);
        _mint(0xC86cea81d3c320086cE20eFdEc2e65d039136451, 90E18);
        _mint(0xB2C480B570d5d85099DdB62f5Bdbf8294eEb7Bc4, 54E18);
        _mint(0x6C0aC58A28E14Aa72Eb4BA1B5c40f3b82b73DA01, 90E18);
        _mint(0x035000529CffE9f04DB8E81B7A53807E63EeaC12, 90E18);
        _mint(0x759878ffA1a043064F7b1a46869F7360D0e1bEd0, 45E18);
        _mint(0x3151335A0f4Dd51fc553c39d3003AcBb59568f09, 72E18);
        _mint(0x1E46Fc7c886aAcfB46d774d2281C0a64747Fd50a, 45E18);
        _mint(0x9CF3D7E809D4DB6B97281e0092603Ed93D84998F, 45E18);
        _mint(0xDF219a91C6e6eb0506b5d658b0ebB99Aa978195c, 675E17);
        _mint(0x452Eacc327d4B9764A54E031A33C0D7a4b290746, 90E18);
        _mint(0x7222659adc246fd757B411d34E786F27E644708c, 45E18);
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
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }














    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 burnAmount = _getBurnAmount(amount);
        _burnTotalSupply(burnAmount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount.sub(burnAmount));
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }











    function _burnTotalSupply(uint256 amount) internal virtual {
        _totalSupply = _totalSupply.sub(amount);
        emit burnTotalSupply(amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }








    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }




    function _getBurnAmount(uint256 amount) internal view virtual returns (uint256) {
        if (_totalSupply<=_threshold) {
            return 0;
        }
        return amount.mul(_burnRate).div(1000);
    }
}
