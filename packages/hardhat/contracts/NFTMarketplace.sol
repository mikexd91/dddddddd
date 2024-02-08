// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the necessary contracts from the OpenZeppelin library
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    // The NFT token contract
    IERC721 private _nftContract;

    // Struct to represent a listing
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
    }

    // Array to store all listings
    Listing[] private _listings;

    // Mapping to keep track of the listing index for each token ID
    mapping(uint256 => uint256) private _listingIndex;

    // Fee percentage as an integer value (e.g., 5 means 5%)
    uint256 private _feePercentage;

    // Modifier to check if a listing exists
    modifier listingExists(uint256 tokenId) {
        require(_listingIndex[tokenId] > 0, "Listing does not exist");
        _;
    }

    constructor(address nftContractAddress) {
        // Set the NFT contract address
        _nftContract = IERC721(nftContractAddress);

        // Set the initial fee percentage to 0
        _feePercentage = 0;
    }

    // Function to list an NFT for sale
    function listNFTForSale(uint256 tokenId, uint256 price) external {
        // Check if the caller owns the NFT
        require(_nftContract.ownerOf(tokenId) == msg.sender, "Caller does not own the NFT");

        // Create a new listing
        Listing memory listing = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true
        });

        // Add the listing to the array
        _listings.push(listing);

        // Update the listing index mapping
        _listingIndex[tokenId] = _listings.length;

        // Transfer the ownership of the NFT to the marketplace contract
        _nftContract.transferFrom(msg.sender, address(this), tokenId);
    }

    // Function to change the price of a listed NFT
    function changeListingPrice(uint256 tokenId, uint256 price) external listingExists(tokenId) {
        // Get the listing index
        uint256 index = _listingIndex[tokenId] - 1;

        // Check if the caller is the seller
        require(_listings[index].seller == msg.sender, "Caller is not the seller");

        // Update the listing price
        _listings[index].price = price;
    }

    // Function to unlist a listed NFT
    function unlistNFT(uint256 tokenId) external listingExists(tokenId) {
        // Get the listing index
        uint256 index = _listingIndex[tokenId] - 1;

        // Check if the caller is the seller
        require(_listings[index].seller == msg.sender, "Caller is not the seller");

        // Remove the listing from the array
        delete _listings[index];

        // Update the listing index mapping
        delete _listingIndex[tokenId];

        // Transfer the ownership of the NFT back to the seller
        _nftContract.transferFrom(address(this), msg.sender, tokenId);
    }

    // Function to buy a listed NFT
    function buyNFT(uint256 tokenId) external payable listingExists(tokenId) {
        // Get the listing index
        uint256 index = _listingIndex[tokenId] - 1;

        // Get the listing
        Listing memory listing = _listings[index];

        // Check if the listing is active
        require(listing.active, "Listing is not active");

        // Verify the payment amount
        require(msg.value >= listing.price, "Insufficient payment amount");

        // Calculate the fee amount
        uint256 feeAmount = (listing.price * _feePercentage) / 100;

        // Calculate the seller proceeds
        uint256 sellerProceeds = listing.price - feeAmount;

        // Transfer the payment amount to the seller
        payable(listing.seller).transfer(sellerProceeds);

        // Transfer the fee amount to the marketplace owner
        payable(owner()).transfer(feeAmount);

        // Transfer the ownership of the NFT to the buyer
        _nftContract.transferFrom(address(this), msg.sender, tokenId);

        // Remove the listing from the array
        delete _listings[index];

        // Update the listing index mapping
        delete _listingIndex[tokenId];
    }

    // Function to set the fee percentage
    function setFeePercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Invalid fee percentage");
        _feePercentage = percentage;
    }

    // Function to get the fee percentage
    function getFeePercentage() external view returns (uint256) {
        return _feePercentage;
    }

    // Function to get the total number of listings
    function getTotalListings() external view returns (uint256) {
        return _listings.length;
    }

    // Function to get the details of a listing
    function getListing(uint256 index) external view returns (uint256, address, uint256, bool) {
        Listing memory listing = _listings[index];
        return (listing.tokenId, listing.seller, listing.price, listing.active);
    }
}