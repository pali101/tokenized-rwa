// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RWAToken.sol";

contract RWAStableCoin is ERC20, Ownable {
    RWAToken public rwaToken;
    uint256 public constant COLLATERAL_RATIO = 120;
    // uint256 public constant LIQUIDATION_THRESHOLD = 120;

    // property id => number of shares locked
    mapping(uint256 => uint256) public collateralLocked;

    event StablecoinMinted(
        address indexed user,
        uint256 propertyId,
        uint256 amount
    );
    event StablecoinBurned(address indexed user, uint256 amount);
    event RWARefunded(address indexed user, uint256 propertyId, uint256 shares);
    event LiquidationTriggered(
        uint256 indexed propertyId,
        uint256 liquidatedShares,
        uint256 burnedStablecoins
    );

    constructor(
        address rwaTokenAddress
    ) ERC20("RWA Stablecoin", "RSC") Ownable(msg.sender) {
        rwaToken = RWAToken(rwaTokenAddress);
    }

    function mintStableCoin(uint256 propertyId, uint256 shares) external {
        require(
            rwaToken.balanceOf(msg.sender, propertyId) >= shares,
            "Not enough RWA tokens"
        );
        require(rwaToken.whitelistedInvestors(msg.sender), "Not whitelisted");

        (, uint256 propertyValue, uint256 numberOfShares) = rwaToken.properties(
            propertyId
        );
        uint256 shareValue = propertyValue / numberOfShares;
        // here shares is used for number of shares being pegged for this particular property
        uint256 stableCoinAmount = (shareValue * shares) / COLLATERAL_RATIO;

        require(stableCoinAmount > 0, "Minting amount too low");

        rwaToken.safeTransferFrom(
            msg.sender,
            address(this),
            propertyId,
            shares,
            ""
        );
        collateralLocked[propertyId] += shares;

        _mint(msg.sender, stableCoinAmount);
        emit StablecoinMinted(msg.sender, propertyId, stableCoinAmount);
    }

    function redeemStableCoin(
        uint256 propertyId,
        uint256 stableCoinAmount
    ) external {
        (, uint256 propertyValue, uint256 totalShares) = rwaToken.properties(
            propertyId
        );
        require(totalShares > 0, "invalid property");

        uint256 shareValue = propertyValue / totalShares;
        uint256 sharesToReturn = (stableCoinAmount * COLLATERAL_RATIO) /
            shareValue;

        require(
            collateralLocked[propertyId] >= sharesToReturn,
            "Not enough collateralized RWA shares"
        );

        _burn(msg.sender, stableCoinAmount);
        rwaToken.safeTransferFrom(
            address(this),
            msg.sender,
            propertyId,
            sharesToReturn,
            ""
        );
        collateralLocked[propertyId] -= sharesToReturn;

        emit StablecoinBurned(msg.sender, stableCoinAmount);
        emit RWARefunded(msg.sender, propertyId, sharesToReturn);
    }

    // Does not make sense to overcollateratize to 150%, it isn't DeFi protocol with high liquidity
    // RWA are usually much more stable
}
