// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
contract TokenBase is ERC20, AccessControl  {
    using SafeMath for uint256;

    address public _marketingWallet;
    address public _presaleContract;
    address public _publicSaleContract;
    address payable public _taxAddrWallet;
    mapping(address => address) public _referees;
    uint256 _referralPercentage = 3; // referee get 3% of transfer amount
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bool private tradingOpen;
    mapping (address => bool) public _isToExcludedFromTax;
    mapping (address => bool) public _isFromExcludedFromTax;
    uint256 public _buyTaxPercentage;
    uint256 public _sellTaxPercentage;
    mapping (address => bool) private bots;
    constructor(string memory name, string memory symbol, uint256 totalSupply) 
        ERC20(name, symbol) 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, totalSupply);
    }
    function setAddressExcludedFromTax(address[] memory addressesFrom, address[] memory addressesTo) onlyRole(DEFAULT_ADMIN_ROLE) public{
        uint8 i = 0;
        while(i < addressesFrom.length) {
            i++;
            _isFromExcludedFromTax[addressesFrom[i]]=true;
        }
        i=0;
        while(i < addressesTo.length) {
            i++;
            _isToExcludedFromTax[addressesTo[i]]=true;
        }
    }
    function removeAddressExcludedFromTax(address[] memory addressesFrom, address[] memory addressesTo) onlyRole(DEFAULT_ADMIN_ROLE) public{
        uint8 i = 0;
        while(i < addressesFrom.length) {
            i++;
            _isFromExcludedFromTax[addressesFrom[i]]=false;
        }
        i=0;
        while(i < addressesTo.length) {
            i++;
            _isToExcludedFromTax[addressesTo[i]]=false;
        }
    }
    function openTrading() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!tradingOpen,"trading is already open");
        tradingOpen = true;
    }
    function setReferralPercent(uint8 referralPercentage) onlyRole(DEFAULT_ADMIN_ROLE) public{
        require(referralPercentage>=0 && referralPercentage<100, "0<=,<100");
        _referralPercentage=referralPercentage;
    }
    function setTaxPercent(uint8 buyTaxPercentage, uint8 sellTaxPercent) onlyRole(DEFAULT_ADMIN_ROLE) public{
        require(buyTaxPercentage>=0 && buyTaxPercentage<100, "0<=,<100");
        require(sellTaxPercent>=0 && sellTaxPercent<100, "0<=,<100");
        _buyTaxPercentage=buyTaxPercentage;
        _sellTaxPercentage=sellTaxPercent;
    }
    function setMarketingWallet(address marketingWallet) public  onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
        _marketingWallet = marketingWallet;
        return true;
    }
    function setTaxAddrWallet(address taxAddrWallet) public  onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
        _taxAddrWallet = payable(taxAddrWallet);
        return true;
    }

    function setPresaleContract(address presaleContract) onlyRole(DEFAULT_ADMIN_ROLE) public returns(bool){
        _presaleContract = presaleContract;
        return true;
    }
    function setPublicSaleContract(address publicSaleContract) onlyRole(DEFAULT_ADMIN_ROLE) public returns(bool){
        _publicSaleContract = publicSaleContract;
        return true;
    }

    function setReferee(address referee) public returns(bool){
        require(msg.sender != referee, "can not be self");
        _referees[msg.sender] = referee;
        return true;
    }



    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE){
        _mint(_to, _amount);
    }

    function burn(address _owner, uint256 _amount) external onlyRole(BURNER_ROLE) {
        _burn(_owner, _amount);
    }
    function setBots(address[] memory bots_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bots[notbot] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!bots[from] && !bots[to]);
        //if tradeOpen
        if(!tradingOpen){
            require(to==_publicSaleContract || to==_presaleContract || from!=address(0) || to!=address(0), "not open");
        }
        //referral
        if((from==_presaleContract || from==_publicSaleContract) && to!=address(0)){ // when presale
            address referee = _referees[to];
            if(referee!=address(0)){ // if referee is set for receiver
                uint256 rewardamount = amount.mul(_referralPercentage).div(100);
                rewardamount = min(rewardamount, balanceOf(_marketingWallet));
                if(rewardamount>0){
                        _burn(_marketingWallet, rewardamount);
                        _mint(referee, rewardamount);
                } 
            }
        }
        //tax
        //sell
        if(to==_publicSaleContract && !_isFromExcludedFromTax[from] && from!=address(0)){
            uint256 taxAmount = amount.mul(_sellTaxPercentage).div(100);
            taxAmount = min(taxAmount, balanceOf(from));
            if(taxAmount>0){
                _burn(from, taxAmount);
                _mint(_taxAddrWallet, taxAmount);                    
            } 
        }
       
    } 
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {       
        //tax
        //buy
        if(from==_publicSaleContract && !_isToExcludedFromTax[to] && to!=address(0)){
            uint256 taxAmount = amount.mul(_buyTaxPercentage).div(100);
            taxAmount = min(taxAmount, balanceOf(to));
            if(taxAmount>0){
                    _burn(to, taxAmount);
                    _mint(_taxAddrWallet, taxAmount);                    
            } 
        }

    } 
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

}
