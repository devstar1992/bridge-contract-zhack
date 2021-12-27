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
    IERC20 public token;
    mapping(address => uint256) public nonce;
    mapping(address => mapping(uint256 => bool)) public processedNonces;
    uint8 public fee;
    function setFee(uint8 _fee) public{
        require(msg.sender == admin, "only admin");
        fee=_fee;
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
        if(nonce[msg.sender]==0)
            nonce[msg.sender]++;
        else
            nonce[msg.sender]=0;
        token.burn(msg.sender, _amount);
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
        token.mint(_to, _amount.mul(fee).div(100));
    }

    function getBalance(address aa) public view returns (uint256) {
        return token.balanceOf(aa);
    }

    function getServerBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

}