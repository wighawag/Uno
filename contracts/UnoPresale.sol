// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts-3.4.1/GSN/Context.sol";
import "@openzeppelin/contracts-3.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-3.4.1/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-3.4.1/math/SafeMath.sol";
import "@openzeppelin/contracts-3.4.1/utils/Address.sol";
import "@openzeppelin/contracts-3.4.1/access/Ownable.sol";

contract UnoPresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public UNO; // 9 decimals
    IERC20 public BUSD; // 18 decimals

    mapping(address => bool) public whitelistedAddresses;
    mapping(address => bool) public boughtUNO;
    mapping(address => uint256) public claimable;

    uint256 public price;
    uint256 public unoTarget;
    uint256 public totalOwed;
    uint256 public busdRaised;
    uint256 public totalWhitelisted;

    bool public startUnlocked;
    bool public endUnlocked;
    bool public claimUnlocked;
    bool public isInitialized;

    event StartUnlockedEvent(uint256 startTimestamp);
    event EndUnlockedEvent(uint256 endTimestamp);
    event ClaimUnlockedEvent(uint256 claimTimestamp);


    modifier notInitialized() {
        require( !isInitialized );
        _;
    }

    constructor(
        IERC20 _busd,
        IERC20 _uno
    ) {
        BUSD = IERC20(_busd);
        UNO = IERC20(_uno); //9 decimals
        totalOwed = 0;
        busdRaised = 0;
    }

    function initialize(
        uint256 _unoTarget,
        uint256 _price
    ) external onlyOwner() notInitialized() returns ( bool ) {
        unoTarget = _unoTarget;
        price = _price;
        isInitialized = true;
        return true;
    }

// Functions to whitelist.
    function addWhitelistedAddress(address _address) external onlyOwner() {
        whitelistedAddresses[_address] = true;
        totalWhitelisted = totalWhitelisted.add(1);
    }

    function addMultipleWhitelistedAddresses(address[] calldata _addresses) external onlyOwner() {
         for (uint i=0; i<_addresses.length; i++) {
             whitelistedAddresses[_addresses[i]] = true;
         }
         totalWhitelisted = totalWhitelisted.add( _addresses.length );
    }

    function removeWhitelistedAddress(address _address) external onlyOwner() {
        whitelistedAddresses[_address] = false;
        totalWhitelisted = totalWhitelisted.sub(1);
    }
// Functions before unlockStart() to set how much Uno is offered, at what price.
// Uno target is 9 decimals
    function setUnoTarget(uint256 _unoTarget) external onlyOwner() {
        require(!startUnlocked, 'Presale already started!');
        unoTarget = _unoTarget;
    }
// Price in 18 decimals
    function setPrice(uint256 _price) external onlyOwner() {
        require(!startUnlocked, 'Presale already started!');
        price= _price;
    }


// Functions including unlockStart() during presale.
    function unlockStart() external onlyOwner() {
        require(!startUnlocked, 'Presale already started!');
        require(isInitialized, 'Presale is not Initialized');
        startUnlocked = true;
        StartUnlockedEvent(block.timestamp);
    }

    function getAllotmentPerBuyer() public view returns (uint) {
        require(totalWhitelisted > 0, 'Nobody is Whitelisted');
        return (unoTarget.sub(totalOwed)).div(totalWhitelisted).mul(price).div(1e9);
    }

    function buy(uint _amountBUSD) public returns(bool) {
        require(startUnlocked, 'presale has not yet started');
        require(!endUnlocked, 'presale already ended');
        require(whitelistedAddresses[msg.sender] == true, 'you are not whitelisted');
        require(boughtUNO[msg.sender] == false, 'Already Participated');
        require(_amountBUSD <= getAllotmentPerBuyer(), 'More than alloted');

        boughtUNO[msg.sender] = true;

        BUSD.safeTransferFrom(msg.sender, address(this), _amountBUSD);
        claimable[msg.sender] = claimable[msg.sender].add(_amountBUSD.div(price)).mul(1e9);
        totalOwed = totalOwed.add(_amountBUSD.div(price).mul(1e9));
        busdRaised = busdRaised.add(_amountBUSD);
        totalWhitelisted = totalWhitelisted.sub(1);
        return true;
    }

// Functions inlcuding unlockEnd() after presale.
    function unlockEnd() external onlyOwner() {
        require(!endUnlocked, 'Presale already ended!');
        endUnlocked = true;
        EndUnlockedEvent(block.timestamp);
    }

// Functions including unlockClaim() for when claimable.
    function unlockClaim() external onlyOwner() {
        require(endUnlocked, 'Presale has not ended!');
        require(!claimUnlocked, 'Claim already unlocked!');
        claimUnlocked = true;
        ClaimUnlockedEvent(block.timestamp);
    }

// Returns Uno claimable in 9 decimals
    function claimableAmount(address user) external view returns (uint256) {
        return claimable[user];
    }

    function claim() external {
        require(claimUnlocked, 'claiming not allowed yet');
        require(whitelistedAddresses[msg.sender] == true, 'you are not whitelisted');
        require(claimable[msg.sender] > 0, 'nothing to claim');

        uint256 amount = claimable[msg.sender];

        claimable[msg.sender] = 0;
        totalOwed = totalOwed.sub(amount);

        require(UNO.transfer(msg.sender, amount), 'failed to claim');
    }

    function withdrawRemainingBusd() external onlyOwner() returns(bool) {
        require(startUnlocked, 'presale has not started!');
        require(endUnlocked, 'presale has not yet ended!');
        BUSD.safeTransfer(msg.sender, BUSD.balanceOf(address(this)));
        return true;
    }
}








