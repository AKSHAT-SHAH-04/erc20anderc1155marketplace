pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract marketplace is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint256 amount;         
        uint256 lastUpdateAt;   
        uint256 pointsDebt;     
    
     }
    
    struct NFTInfo {
        address contractAddress;
        uint256 id;             
        uint256 remaining;      
        uint256 price;          
         }
    
    uint256 public emissionRate;       
    IERC20 lpToken;                   
    
    NFTInfo[] public nftInfo;
    mapping(address => UserInfo) public userInfo;
    
    constructor(uint256 _emissionRate, IERC20 _lpToken) public {
        emissionRate = _emissionRate;
        lpToken = _lpToken;
    }
    
    function addNFT(
        address contractAddress,    
        uint256 id,
        uint256 total,             
        uint256 price
    ) external onlyOwner {
        IERC1155(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            id,
            total,
            ""
        );
        nftInfo.push(NFTInfo({
            contractAddress: contractAddress,
            id: id,
            remaining: total,
            price: price
        }));
    }
    
    function deposit(uint256 _amount) external {
        lpToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        
        UserInfo storage user = userInfo[msg.sender];
        
        
        if(user.amount != 0) {
            user.pointsDebt = pointsBalance(msg.sender);
        }
        user.amount = user.amount.add(_amount);
        user.lastUpdateAt = now;
    }
    
    
    function claim(uint256 _nftIndex, uint256 _quantity) public {
        NFTInfo storage nft = nftInfo[_nftIndex];
        require(nft.remaining > 0, "All NFTs farmed");
        require(pointsBalance(msg.sender) >= nft.price.mul(_quantity), "Insufficient Points");
        UserInfo storage user = userInfo[msg.sender];
        
        
        user.pointsDebt = pointsBalance(msg.sender).sub(nft.price.mul(_quantity));
        user.lastUpdateAt = now;
        
        
        IERC1155(nft.contractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            nft.id,
            _quantity,
            ""
        );
        
        nft.remaining = nft.remaining.sub(_quantity);
    }

    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Insufficient staked");
        
        
        user.pointsDebt = pointsBalance(msg.sender);
        user.amount = user.amount.sub(_amount);
        user.lastUpdateAt = now;
        
        lpToken.safeTransfer(
            msg.sender,
            _amount
        );
    }
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
    function pointsBalance(address userAddress) public view returns (uint256) {
        UserInfo memory user = userInfo[userAddress];
        return user.pointsDebt;
    }
    
}