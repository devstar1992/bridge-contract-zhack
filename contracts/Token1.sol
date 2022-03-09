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
    address public _router;
    address public marketingWallet;
    address public presaleContract;
    address public publicSaleContract;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bool public tradingOpen;
    mapping (address => bool) public isExcludedFromTax;
    uint256[3] public lpTaxPercentage;
    uint256[3] public marketingTaxPercentage;
    mapping (address => bool) public _bots;
    bool public updateStop;
    address[] public holders;

    event LogOpenTrading(bool open); 
    event LogUpdateTaxPercentage(
            uint256[3] _old_lpTaxPercentage, 
            uint256[3] _old_marketingTaxPercentage,
            uint256[3] _lpTaxPercentage,
            uint256[3] _marketingTaxPercentage
        );
    event LogExcludedFromTax(address[] addresses);    
    event LogIncludeFromTax(address[] addresses);    
    event LogUpdateFeeWallets(address old_marketing, address marketingWallet);
    event LogUpdatePresaleContract(address old_presaleContract, address presaleContract);
    event LogUpdatePublicSaleContract(address old_publicContract, address publicSaleContract);
    event Mint(address _to, uint256 _amount);
    event Burn(address _owner, uint256 _amount);
    event LogSetBots(address[] bots);
    event LogDelBots(address[] notbots);
    event LogUpdateStopped(bool _updateStop);
    event LogAddHoler(address _holder);
    event LogRemoveHoler(address _holder);
    event LogRedistribute(uint256 _amount);
    function initialize(
        address admin,
        string memory name,
        string memory symbol,
        uint256 initial_supply,
        address _marketingWallet,
        address router,
        uint256[3] memory _lpTaxPercentage,
        uint256[3] memory _marketingTaxPercentage
    ) public initializer {
        __ERC20_init(name, symbol);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _mint(admin, initial_supply);
        marketingWallet=_marketingWallet;
        _router=router;
        lpTaxPercentage=_lpTaxPercentage;
        marketingTaxPercentage=_marketingTaxPercentage;
        updateStop=false;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function stopUpdate() onlyRole(DEFAULT_ADMIN_ROLE) public{
        require(updateStop==false, "stopped!");
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
        IPancakeRouter02 dexRouter = IPancakeRouter02(_router);

        // create pair
        address lpPair = IPancakeFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        publicSaleContract=lpPair;
        uint256 _amount=balanceOf(address(this));
        // add the liquidity
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        require(_amount > 0, "Must have Tokens on contract to launch");
        _approve(address(this), address(dexRouter), _amount);
        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            _amount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
        emit LogOpenTrading(true);
    }


    function setTaxPercent(
        uint256[3] memory _lpTaxPercentage,
        uint256[3] memory _marketingTaxPercentage
    ) onlyRole(DEFAULT_ADMIN_ROLE) public{
        require(!updateStop, "stop update");
        require(_lpTaxPercentage[0]>=0 && _lpTaxPercentage[0]<1000);
        require(_lpTaxPercentage[1]>=0 && _lpTaxPercentage[1]<1000);
        require(_lpTaxPercentage[2]>=0 && _lpTaxPercentage[2]<1000);       
        require(_marketingTaxPercentage[0]>=0 && _marketingTaxPercentage[0]<1000);
        require(_marketingTaxPercentage[1]>=0 && _marketingTaxPercentage[1]<1000);
        require(_marketingTaxPercentage[2]>=0 && _marketingTaxPercentage[2]<1000);
        require(_lpTaxPercentage[0]+_marketingTaxPercentage[0]<1000);
        require(_lpTaxPercentage[1]+_marketingTaxPercentage[1]<1000);
        require(_lpTaxPercentage[2]+_marketingTaxPercentage[2]<1000);
        uint256[3] memory old_lpTaxPercentage=lpTaxPercentage;
        uint256[3] memory old_marketingTaxPercentage=marketingTaxPercentage;

        lpTaxPercentage=_lpTaxPercentage;
        marketingTaxPercentage=_marketingTaxPercentage;
        emit LogUpdateTaxPercentage(
            old_lpTaxPercentage, 
            old_marketingTaxPercentage,
            lpTaxPercentage,
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
        emit LogUpdatePublicSaleContract(old_publicContract, publicSaleContract);
        return true;
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
        require(!_bots[from] && !_bots[to]);
        if(!tradingOpen){
            require(to==publicSaleContract || to==presaleContract || to==address(this) || from==address(this), "not open");
        }

        uint256 lpTaxAmount=0;
        uint256 marketingTaxAmount=0;
        if(to==publicSaleContract && !isExcludedFromTax[from] && from!=address(this)){
            //sell
            lpTaxAmount = amount.mul(lpTaxPercentage[0]).div(1000);
            marketingTaxAmount=amount.mul(marketingTaxPercentage[0]).div(1000);
        }else if(from==publicSaleContract && !isExcludedFromTax[to] && to!=address(this)){
            //buy
            lpTaxAmount = amount.mul(lpTaxPercentage[1]).div(1000);
            marketingTaxAmount=amount.mul(marketingTaxPercentage[1]).div(1000);
        }else if(!isExcludedFromTax[from] && !isExcludedFromTax[to] && from!=address(this) && to!=address(this)){
            //transfer
            lpTaxAmount = amount.mul(lpTaxPercentage[2]).div(1000);
            marketingTaxAmount=amount.mul(marketingTaxPercentage[2]).div(1000);
        }
        
        if(marketingTaxAmount>0){
            super._transfer(from, publicSaleContract, marketingTaxAmount);
            IPancakePair pair=IPancakePair(publicSaleContract);
            IPancakeRouter02 pancakeRouter=IPancakeRouter02(_router);
            address[] memory tokens=new address[](2);
            tokens[0]=address(this);
            tokens[1]=pancakeRouter.WETH();
            uint256[] memory amountOut = pancakeRouter.getAmountsOut(
              marketingTaxAmount,
              tokens
            );
            if(amountOut[1]>0){
                pair.swap(pair.token0()==address(this) ? 0 : amountOut[1], 
                    pair.token0()==address(this) ? amountOut[1] : 0, 
                    marketingWallet,
                    new bytes(0));
            }
            
          
        }
        if(lpTaxAmount>0){
            super._transfer(from, publicSaleContract, lpTaxAmount);
        }
        uint256 _amount=amount.sub(lpTaxAmount).sub(marketingTaxAmount);
        if(_amount>0){
            _addHolder(to);
            super._transfer(from, to, _amount);        
            
        }
        _removeHolder(from);
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
