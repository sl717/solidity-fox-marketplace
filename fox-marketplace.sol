// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./FoxNFT.sol";


contract FOX {
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {}
    function approve(address spender, uint256 amount) public returns (bool) {}
    function transfer(address recipient, uint256 amount) public returns (bool) {}
    function allowance(address owner, address spender) public view returns (uint256) {}
}

contract Marketplace is AccessControl {

    // Set the MaxQuantity of the production
    uint256 maxQuantity = 10;

    struct FoxProd {
        string name;
        string description;
        uint256 price;
        uint quantity;
        uint8 flag;
    }
    
    bytes32 public constant EDIT_ROLE = keccak256("EDIT_ROLE");
    
    // Mapping Set
    mapping (string => FoxProd) public foxProds;
    string [] hashes;
    
    FoxNFT ft;
    FOX fox;
    
    // In constructor, give the role to msgSender
    constructor(FoxNFT _ft, address _fox) {
        ft = _ft;
        fox = FOX(address(_fox));
        _setupRole(EDIT_ROLE, _msgSender());
    }
    
    // Set and get the MaxQuantity of the production
    function setMaxQuantity(uint256 _quantity) public {
        maxQuantity = _quantity;
    }       
    
    function getMaxQuantity() public view returns(uint256) {
        return maxQuantity;
    }

    // TEST if it has EDIT ROLE
    modifier editable{
        require(hasRole(EDIT_ROLE, _msgSender()), "Must Have Edit Role to Mint");
        _;
    }
    
    // Add new productions into the Marketplace
    function addNewProduction(string memory _name, string memory _description, uint256 _price, uint _quantity, string memory _hash) public editable returns (bool) {       
        require(_quantity <= maxQuantity, "Quantity cannot be higher than the maximum quantity");
        require(foxProds[_hash].flag != 1, "You can't create this production, it is already existed!");
        foxProds[_hash] = FoxProd(_name, _description, _price, _quantity, 1);
        hashes.push(_hash);
        return true;
    }

    // Add some Quantity to the existing Production in the Marketplace
    function addProduction(string memory _hash, uint256 _amount ) public editable returns (bool) {
        require(foxProds[_hash].flag == 1, "You can't add to this production, it isn't existed!");
        require((foxProds[_hash].quantity + _amount) <= maxQuantity  , "The quantity Exceed!");
        foxProds[_hash].quantity += _amount;
        return true;
    }

    // Remove some Quantity from the existing Production in the Marketplace
    function removeProduction(string memory _hash, uint256 _amount ) public editable returns (bool){
        require(foxProds[_hash].flag == 1, "You can't add to this production, it isn't existed!");
        require(foxProds[_hash].quantity >= _amount, "The amount Exceed!");
        foxProds[_hash].quantity -= _amount;
        if (foxProds[_hash].quantity == 0) foxProds[_hash].flag = 0;
        return true;
    }

    // Change the Price
    function changePrice(string memory _hash, uint256 _newPrice) public editable returns (bool){
        require(foxProds[_hash].flag == 1, "The Production is not Existed!");
        foxProds[_hash].price = _newPrice;
        return true;
    }

    // Get FoxProds by using _hash
    function getProdList() public view returns(string[] memory){
        return hashes;
    }    
    function getProdByHash(string memory _hash) public view returns (FoxProd memory){
        return foxProds[_hash];
    }
    
    // Buy the production you want
    function buy(address to, string memory _hash, uint256 _amount ) public payable returns (uint) {
        require(foxProds[_hash].quantity >= 1, "Must have quantity more than 1");
        require(_amount == foxProds[_hash].price * 10**9, "Amount should be same with price");
        require(fox.transferFrom(msg.sender, address(0x1), _amount), "ERC20: transfer amount exceeds allowance");
        ft.mint(to, _hash);
        foxProds[_hash].quantity = foxProds[_hash].quantity - 1;
        return foxProds[_hash].quantity;
    }
}