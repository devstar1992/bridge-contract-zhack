// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address whom) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function burn(address owner, uint256 amount) external;
}

contract BridgeBase{
    using SafeMath for uint256;
    address public admin;
    address public feeWallet;
    IERC20 public token;
    mapping(address => uint256) public nonce;
    mapping(address => mapping(uint256 => bool)) public processedNonces;
    uint8 public fee;
    function setFee(uint8 _fee, address _feeWallet) public{
        require(msg.sender == admin, "only admin");
        require(_fee>=0 && _fee<1000, "0<=,<1000");
        fee=_fee;
        feeWallet=_feeWallet;
    }

    event Convert(
        address from,
        uint8 network,
        address to,
        uint256 amount,
        uint256 date,
        uint256 nonce
    );
    constructor(address _token) {
        admin = msg.sender;
        token = IERC20(_token);
    }

    function burn(uint8 network, address _to, uint256 _amount) public{  
        nonce[msg.sender]++;
        token.burn(msg.sender, _amount);
        if(fee>0)
            token.mint(feeWallet, _amount.mul(fee).div(2000));

        emit Convert(
            msg.sender,
            network, 
            _to,
            _amount,
            block.timestamp,
            nonce[msg.sender]
        );
    }

    function mint(address _to, uint256 _amount, uint256 _nonce) public {
        require(msg.sender == admin, "only admin");
        require(processedNonces[msg.sender][_nonce] == false, "already mint");
        processedNonces[msg.sender][_nonce]=true;
        token.mint(_to, _amount.mul(100-fee).div(1000));
        if(fee>0)
            token.mint(feeWallet, _amount.mul(fee).div(2000));
    }

    function getBalance(address aa) public view returns (uint256) {
        return token.balanceOf(aa);
    }

    function getServerBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

}