// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import './IPancakeRouter02.sol';
import './IPancakeFactory.sol';
import './IPancakePair.sol';
contract Token is Initializable, ERC20Upgradeable, AccessControlUpgradeable  {
    using SafeMathUpgradeable for uint256;
    address public admin;
    address public marketingWallet;
    address public presaleContract;
    address public publicSaleContract;
    mapping(address => address) public referees;
    uint256 public referralPercentage; // referee get 3% of transfer amount
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bool public tradingOpen;
    mapping (address => bool) public isExcludedFromTax;
    uint256[3] public lpTaxPercentage;
    uint256[3] public communityTaxPercentage;
    uint256[3] public marketingTaxPercentage;
    mapping (address => bool) public _bots;
    bool public updateStop;
    address[] public holders;
    uint256 public referralAmount;
    uint256 public communityAmount;
    IPancakePair pair;
    IPancakeRouter02 pancakeRouter;

    event LogOpenTrading(bool open); 
    event LogUpdateReferralPercentage(uint256 old_val, uint256 new_val); 
    event LogAddReferralAmount(uint256 oldReferralAmount,uint256 referralAmount);
    event LogUpdateTaxPercentage(
            uint256[3] _old_lpTaxPercentage, 
            uint256[3] _old_communityTaxPercentage, 
            uint256[3] _old_marketingTaxPercentage,
            uint256[3] _lpTaxPercentage,
            uint256[3] _communityTaxPercentage,
            uint256[3] _marketingTaxPercentage
        );
    event LogExcludedFromTax(address[] addresses);    
    event LogIncludeFromTax(address[] addresses);    
    event LogUpdateFeeWallets(address old_marketingWallet, address marketingWallet);
    event LogUpdatePresaleContract(address old_presaleContract, address presaleContract);
    event LogUpdatePublicSaleContract(address old_publicContract, address publicSaleContract);
    event Mint(address _to, uint256 _amount);
    event Burn(address _owner, uint256 _amount);
    event LogSetBots(address[] bots);
    event LogDelBots(address[] notbots);
    event LogUpdateStopped(bool _updateStop);
    event LogSetReferee(address wallet, address referrer);
    event LogAddHoler(address _holder);
    event LogRemoveHoler(address _holder);
    event LogRedistribute(uint256 _amount);
    function initialize(
        address _admin,
        string memory name,
        string memory symbol,
        uint256 initial_supply,
        address _marketingWallet,
        address router,
        uint256[3] memory _lpTaxPercentage,
        uint256[3] memory _communityTaxPercentage,
        uint256[3] memory _marketingTaxPercentage,
        uint256 _referralPercentage,
        uint256 _referralAmount
    ) public initializer {
        __ERC20_init(name, symbol);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _mint(_admin, initial_supply);
        admin=_admin;
        marketingWallet=_marketingWallet;
        pancakeRouter=IPancakeRouter02(router);
        lpTaxPercentage=_lpTaxPercentage;
        communityTaxPercentage=_communityTaxPercentage;
        marketingTaxPercentage=_marketingTaxPercentage;
        referralPercentage=_referralPercentage;
        referralAmount=_referralAmount;
        updateStop=false;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function stopUpdate() onlyRole(DEFAULT_ADMIN_ROLE) public{
        require(!updateStop, "stopped!");
        updateStop=true;
        emit LogUpdateStopped(true);
    }

    function excludedFromTax(address[] memory addresses) onlyRole(DEFAULT_ADMIN_ROLE) public{
        uint256 i = 0;
        while(i < addresses.length) {            
            isExcludedFromTax[addresses[i]]=true;
            i++;
        } 
        emit LogExcludedFromTax(addresses);      
    }
    function includeInTax(address[] memory addresses) onlyRole(DEFAULT_ADMIN_ROLE) public{
        uint256 i = 0;
        while(i < addresses.length) {            
            isExcludedFromTax[addresses[i]]=false;
            i++;
        }  
        emit LogIncludeFromTax(addresses);      
    }
    function openTrading() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!tradingOpen,"trading is already open");
        tradingOpen = true;

        // create pair
        address lpPair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        publicSaleContract=lpPair;
        pair=IPancakePair(publicSaleContract);
        require(balanceOf(address(this))>referralAmount, "no balance");
        uint256 _amount=balanceOf(address(this)).sub(referralAmount);
        // add the liquidity
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        require(_amount > 0, "Must have Tokens on contract to launch");
        _approve(address(this), address(pancakeRouter), _amount);
        pancakeRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            _amount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
        emit LogOpenTrading(true);
    }
    function setReferralPercentage(uint256 _referralPercentage) onlyRole(DEFAULT_ADMIN_ROLE) public{
        require(!updateStop, "stop update");
        require(_referralPercentage>=0 && _referralPercentage<1000, "0<=,<1000");
        uint256 oldReferral=referralPercentage;
        referralPercentage=_referralPercentage;
        emit LogUpdateReferralPercentage(oldReferral, _referralPercentage);
    }
    function addReferralAmount(uint256 _referralAmount) onlyRole(DEFAULT_ADMIN_ROLE) public{
        require(_referralAmount>=0, "mount>0");
        super._transfer(msg.sender, address(this), _referralAmount);
        uint256 oldReferralAmount=referralAmount;
        referralAmount=referralAmount.add(_referralAmount);
        emit LogAddReferralAmount(oldReferralAmount, referralAmount);
    }
    function setTaxPercent(
        uint256[3] memory _lpTaxPercentage,
        uint256[3] memory _communityTaxPercentage,
        uint256[3] memory _marketingTaxPercentage
    ) onlyRole(DEFAULT_ADMIN_ROLE) public{
        require(!updateStop, "stop update");
        require(_lpTaxPercentage[0]>=0 && _lpTaxPercentage[0]<1000);
        require(_lpTaxPercentage[1]>=0 && _lpTaxPercentage[1]<1000);
        require(_lpTaxPercentage[2]>=0 && _lpTaxPercentage[2]<1000);
        require(_communityTaxPercentage[0]>=0 && _communityTaxPercentage[0]<1000);
        require(_communityTaxPercentage[1]>=0 && _communityTaxPercentage[1]<1000);
        require(_communityTaxPercentage[2]>=0 && _communityTaxPercentage[2]<1000);
        require(_marketingTaxPercentage[0]>=0 && _marketingTaxPercentage[0]<1000);
        require(_marketingTaxPercentage[1]>=0 && _marketingTaxPercentage[1]<1000);
        require(_marketingTaxPercentage[2]>=0 && _marketingTaxPercentage[2]<1000);
        require(_lpTaxPercentage[0]+_communityTaxPercentage[0]+_marketingTaxPercentage[0]<1000);
        require(_lpTaxPercentage[1]+_communityTaxPercentage[1]+_marketingTaxPercentage[1]<1000);
        require(_lpTaxPercentage[2]+_communityTaxPercentage[2]+_marketingTaxPercentage[2]<1000);
        uint256[3] memory old_lpTaxPercentage=lpTaxPercentage;
        uint256[3] memory old_communityTaxPercentage=communityTaxPercentage;
        uint256[3] memory old_marketingTaxPercentage=marketingTaxPercentage;

        lpTaxPercentage=_lpTaxPercentage;
        communityTaxPercentage=_communityTaxPercentage;
        marketingTaxPercentage=_marketingTaxPercentage;
        emit LogUpdateTaxPercentage(
            old_lpTaxPercentage, 
            old_communityTaxPercentage, 
            old_marketingTaxPercentage,
            lpTaxPercentage,
            communityTaxPercentage,
            marketingTaxPercentage
        );
    }
    function setWallets(address _marketingWallet) public  onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
        require(!updateStop, "stop update");
        require(_marketingWallet != address(0), "_marketingWallet can not be 0 address");
        address old_marketing=marketingWallet;
        marketingWallet = _marketingWallet;
        emit LogUpdateFeeWallets(old_marketing, marketingWallet);
        return true;
    }


    function setPresaleContract(address _presaleContract) onlyRole(DEFAULT_ADMIN_ROLE) public returns(bool){
        require(!updateStop, "stop update");
        require(_presaleContract != address(0), "_presaleContract can not be 0 address");
        address old_presaleContract=presaleContract;
        presaleContract = _presaleContract;
        emit LogUpdatePresaleContract(old_presaleContract, presaleContract);
        return true;
    }
    function setPublicSaleContract(address _publicSaleContract) onlyRole(DEFAULT_ADMIN_ROLE) public returns(bool){
        require(!updateStop, "stop update");
        require(_publicSaleContract != address(0), "_publicSaleContract can not be 0 address");
        address old_publicContract=publicSaleContract;
        publicSaleContract = _publicSaleContract;
        pair=IPancakePair(publicSaleContract);
        emit LogUpdatePublicSaleContract(old_publicContract, publicSaleContract);
        return true;
    }

    function setReferee(address _referee) public {
        require(msg.sender != _referee, "can not be self");
        require(_referee != address(0), "_referee can not be 0 address");
        referees[msg.sender] = _referee;
        emit LogSetReferee(msg.sender, _referee);
    }

    function redistribute() onlyRole(DEFAULT_ADMIN_ROLE) public {
        require(communityAmount<=balanceOf(address(this)) && communityAmount>0, "no balance");
        uint256 _amount=communityAmount.div(holders.length);
        for(uint i=0;i<holders.length;i++)
        {
            super._transfer(address(this), holders[i], _amount);
        }
        communityAmount=0;
        emit LogRedistribute(_amount);
    }


    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE){
        require(_to != address(0), "_to can not be 0 address");
        if(_amount>0)
        {
            _addHolder(_to);
            _mint(_to, _amount);
            emit Mint(_to, _amount);
        }
        
    }

    function burn(address _owner, uint256 _amount) external onlyRole(BURNER_ROLE) {
        require(_owner != address(0), "_owner can not be 0 address");
        if(_amount>0)
        {
            _burn(_owner, _amount);
            _removeHolder(_owner);
            emit Burn(_owner, _amount);
        }
        
    }
    function setBots(address[] memory bots) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < bots.length; i++) {
            _bots[bots[i]] = true;
        }
        emit LogSetBots(bots);
    }
    
    function delBots(address[] memory notbots) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < notbots.length; i++) {
            _bots[notbots[i]] = false;
        }
        emit LogDelBots(notbots);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(referralPercentage>0 && referees[from]!=address(0) && referralAmount>0){ 
            uint256 _amountReferral=amount.mul(referralPercentage).div(1000)>referralAmount ? referralAmount : amount.mul(referralPercentage).div(1000);
            super._transfer(address(this), referees[from], _amountReferral);
            referralAmount=referralAmount.sub(_amountReferral);
        }
        require(!_bots[from] && !_bots[to]);
        if(!tradingOpen){
            require(to==publicSaleContract || to==presaleContract || to==address(this) || from==address(this), "not open");
        }

        uint256 lpTaxAmount=0;
        uint256 communityTaxAmount=0;
        uint256 marketingTaxAmount=0;
        address[] memory path=new address[](2);
        path[0]=address(this);
        path[1]=pancakeRouter.WETH();
        if(to==publicSaleContract && !isExcludedFromTax[from] && from!=address(this)){
            //sell
            lpTaxAmount = amount.mul(lpTaxPercentage[0]).div(1000);
            communityTaxAmount=amount.mul(communityTaxPercentage[0]).div(1000);
            marketingTaxAmount=amount.mul(marketingTaxPercentage[0]).div(1000);
        }else if(from==publicSaleContract && !isExcludedFromTax[to] && to!=address(this)){
            //buy
            lpTaxAmount = amount.mul(lpTaxPercentage[1]).div(1000);
            communityTaxAmount=amount.mul(communityTaxPercentage[1]).div(1000);
            marketingTaxAmount=amount.mul(marketingTaxPercentage[1]).div(1000);
        }else if(!isExcludedFromTax[from] && !isExcludedFromTax[to] && from!=address(this) && to!=address(this)){
            //transfer
            lpTaxAmount = amount.mul(lpTaxPercentage[2]).div(1000);
            communityTaxAmount=amount.mul(communityTaxPercentage[2]).div(1000);
            marketingTaxAmount=amount.mul(marketingTaxPercentage[2]).div(1000);
        }
        
        if(marketingTaxAmount>0){
            super._transfer(from, publicSaleContract, marketingTaxAmount);            
            uint256[] memory amountOut = pancakeRouter.getAmountsOut(
              marketingTaxAmount,
              path
            );
            if(amountOut[1]>0){
                pair.swap(pair.token0()==address(this) ? 0 : amountOut[1], 
                    pair.token0()==address(this) ? amountOut[1] : 0, 
                    marketingWallet,
                    new bytes(0));
            }else
                marketingTaxAmount=0;       
        }
        if(lpTaxAmount.div(2)>0){
            super._transfer(from, address(this), lpTaxAmount);
            uint256 _lpExchangeToETH=lpTaxAmount.div(2);
            _approve(address(this), address(pancakeRouter), _lpExchangeToETH);
            uint256 initialBalance = address(this).balance;
            pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _lpExchangeToETH,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
            uint256 addedBalance = address(this).balance.sub(initialBalance);
            if(addedBalance>0){
                _approve(address(this), address(pancakeRouter), _lpExchangeToETH);

                // add the liquidity
                pancakeRouter.addLiquidityETH{value: addedBalance}(
                    address(this),
                    _lpExchangeToETH,
                    0, // slippage is unavoidable
                    0, // slippage is unavoidable
                    admin,
                    block.timestamp
                );
            }else{
                super._transfer(address(this), from, lpTaxAmount);
                lpTaxAmount=0;       
            }     
        }else
            lpTaxAmount=0;
            
        if(communityTaxAmount>0){
            super._transfer(from, address(this), communityTaxAmount); 
            communityAmount=communityAmount.add(communityTaxAmount);
        }
        uint256 _amount=amount.sub(lpTaxAmount).sub(communityTaxAmount).sub(marketingTaxAmount);
        if(_amount>0){
            _addHolder(to);
            super._transfer(from, to, _amount);        
            _removeHolder(from);
        }        
    }

    function _addHolder(address _holder) internal{
        if(balanceOf(_holder)==0 && _holder!=address(this) && _holder!=address(0) && _holder!=presaleContract && _holder!=publicSaleContract){
            holders.push(_holder);
            emit LogAddHoler(_holder);
        }
    }
    function _removeHolder(address _holder) internal{
        if(balanceOf(_holder)==0 && _holder!=address(this) && _holder!=address(0) && _holder!=presaleContract && _holder!=publicSaleContract){
            emit LogRemoveHoler(_holder);
            for (uint index=0; index<holders.length; index++) {
                if(holders[uint(index)]==_holder){
                    for (uint i = index; i<holders.length-1; i++){
                        holders[i] = holders[i+1];
                    }
                    delete holders[holders.length-1];
                    holders.pop();
                    break;
                }
            }
        }
    }
    receive() external payable{}
    fallback() external payable{}
}
