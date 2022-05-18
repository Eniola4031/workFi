//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWorkFi {

    struct BountyMetadata {

        uint128 stablePay;
        uint128 nativePay;
        uint96 nativePrice; // 1 NT price in stablecoin (in percent)
        address nativeToken; // NT contract address

        address worker;
        address recruiter;
        bool isClosed;
        uint256 deadline; // In seconds since Unix Epoch
    }

    function acceptWorker(uint32 bountyId, address worker) external;

    function createBounty(
        uint128 stablePay, 
        uint128 nativePay, 
        uint96 nativePrice, 
        address nativeToken, 
        uint256 deadline
    ) external;

    function invest(uint32 bountyId, uint128 stableAmount) external;

    function acceptPayment(uint32 bountyId) external;

    function closeBounty(uint32 bountyId) external;


    /////////////////
    // VIEW FUNCTIONS
    /////////////////

    function getInvestment(uint32 bountyId) external view returns (uint128);
    function getBounty(uint32 bountyId) external view returns (BountyMetadata memory);
    function getBounties() external view returns (BountyMetadata[] memory);

}