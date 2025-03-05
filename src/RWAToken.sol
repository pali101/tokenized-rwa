// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RWAToken is ERC1155, Ownable {
    uint256 public nextPropertyId;

    struct Property {
        uint256 id;
        uint256 valuation; // in USD
        uint256 totalShares;
    }

    mapping(uint256 => Property) public properties;
    // mapping to ensure KYC compliance
    mapping(address => bool) public whitelistedInvestors;
    mapping(uint256 => uint256) private _totalSupply;

    event PropertyMinted(uint256 indexed propertyId, uint256 valuation, uint256 totalShares);
    event PropertyBurned(uint256 indexed propertyId);
    event PropertyForcedTransfer(uint256 indexed propertyId, uint256 blockTime);
    event InvestorWhitelisted(address indexed investor);
    event InvestorRemovedFromWhitelist(address indexed investor);

    modifier onlyWhitelisted(address investor) {
        require(whitelistedInvestors[investor], "Investor is not whitelisted");
        _;
    }

    constructor() ERC1155("https://api.example.com/metadata/{id}.json") Ownable(msg.sender) {}

    function mintProperty(uint256 valuation, uint256 totalShares) external onlyOwner {
        require(valuation > 0, "Invalid valuation");
        require(totalShares > 0, "Invalid number of shares");
        require(whitelistedInvestors[msg.sender], "Owner must be whitelisted");

        uint256 propertyId = nextPropertyId;
        properties[propertyId] = Property(propertyId, valuation, totalShares);
        nextPropertyId++;

        _mint(msg.sender, propertyId, totalShares, "");
        _totalSupply[propertyId] = totalShares;
        emit PropertyMinted(propertyId, valuation, totalShares);
    }

    function addWhitelistedInvestor(address investor) external onlyOwner {
        whitelistedInvestors[investor] = true;
        emit InvestorWhitelisted(investor);
    }

    function removeWhitelistedInvestor(address investor) external onlyOwner {
        whitelistedInvestors[investor] = false;
        emit InvestorRemovedFromWhitelist(investor);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        override
        onlyWhitelisted(to)
    {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyWhitelisted(to) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function updateValuation(uint256 propertyId, uint256 newValuation) external onlyOwner {
        // Todo (If time allows) - Integrate chainlink oracle for automatic pricing
        require(properties[propertyId].id == propertyId, "Property does not exist");
        require(newValuation > 0, "Invalid valuation");
        properties[propertyId].valuation = newValuation;
    }

    function forceTransfer(address from, address to, uint256 propertyId, uint256 amount)
        external
        onlyOwner
        onlyWhitelisted(to)
    {
        super._safeTransferFrom(from, to, propertyId, amount, "");
        emit PropertyForcedTransfer(propertyId, block.timestamp);
    }

    function burnAllShares(uint256 propertyId) external onlyOwner {
        uint256 supply = _totalSupply[propertyId];

        require(balanceOf(msg.sender, propertyId) == supply, "Owner does not hold all shares");
        require(supply > 0, "No shares to burn");

        _burn(msg.sender, propertyId, supply);
        _totalSupply[propertyId] = 0;
        emit PropertyBurned(propertyId);
    }

    function setURI(uint256 propertyId, string memory newURI) external onlyOwner {
        require(properties[propertyId].id == propertyId, "Property does not exist");
        _setURI(newURI);
    }
}
