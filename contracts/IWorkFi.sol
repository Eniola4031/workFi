//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWorkFi {

    struct BountyMetadata {

        uint128 stablePay;
        uint128 nativePay; //
        uint96 nativePrice; // 1 NT price in stablecoin (in percent)
        address nativeToken; // NT contract address

        address worker;
        address recruiter;
        bool isClosed;
        uint256 deadline; // In seconds since Unix Epoch
    }

    /// Called by the recruiter to accept an address as a valid worker.
    /// @param bountyId ID of bounty.
    /// @param worker Address of worker being accepted.
    function acceptWorker(uint32 bountyId, address worker) external;

    /// Called by recruiter in creation of a bounty.
    /// @param stablePay Initial amount of stablecoin to pay worker.
    /// @param nativePay Initial amount of native token to pay worker.
    /// @param nativePrice Listed Price (in stablecoin) of 1 Native Token?
    /// @param nativeToken Address of native token
    /// @param deadline Deadline of bounty (in seconds after unix epoch)
    function createBounty(
        uint128 stablePay, 
        uint128 nativePay, 
        uint96 nativePrice, 
        address nativeToken, 
        uint256 deadline
    ) external;

    /// Called by the investor to invest in bounty.
    /// @param bountyId ID of bounty.
    /// @param stableAmount Amount of stablecoin to invest.
    function invest(uint32 bountyId, uint128 stableAmount) external;

    /// Called by the worker to receive payment. Investors will receive their NT accordingly.
    /// @param bountyId ID of bounty.
    function acceptPayment(uint32 bountyId) external;

    /// Closes an expired bounty.
    /// @param bountyId ID of bounty.
    function closeBounty(uint32 bountyId) external;

    /////////////////
    // VIEW FUNCTIONS
    /////////////////

    /// Get user's current investment of a given bounty (in stablecoin)
    /// @param bountyId ID of bounty.
    function getInvestment(uint32 bountyId) external view returns (uint128);

    /// Get information of a bounty.
    /// @param bountyId ID of bounty.
    function getBounty(uint32 bountyId) external view returns (BountyMetadata memory);

    /// Get information of all bounties.
    function getBounties() external view returns (BountyMetadata[] memory);

}