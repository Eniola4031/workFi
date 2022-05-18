//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IWorkFi.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {
    ISuperfluidToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

contract DummyWorkFi is IWorkFi {

    function acceptWorker(uint32 bountyId, address worker) external { }

    function createBounty(
        uint128 stablePay, 
        uint128 nativePay, 
        uint96 exchangeRate, 
        address nativeToken, 
        uint256 deadline
    ) external returns (uint32) { 
        return 5;
    }

    function invest(uint32 bountyId, uint128 stableAmount) external { }

    function acceptPayment(uint32 bountyId) external { }

    function closeBounty(uint32 bountyId) external { }

    /////////////////
    // VIEW FUNCTIONS
    /////////////////

    function getInvestment(uint32 bountyId) external pure returns (uint128) { return 1000 * (10 ** 18); }

    function getBounty(uint32 bountyId) external view returns (BountyMetadata memory) {

        return BountyMetadata({
            stablePay: 2000 * (10 ** 18),
            nativePay: 1000 * (10 ** 18),
            exchangeRate: 1 ether,
            nativeToken: 0x96B82B65ACF7072eFEb00502F45757F254c2a0D4,
            worker: address(0),
            recruiter: address(1),
            isClosed: false,
            deadline: block.timestamp + 60 days
        });

    }
    function getBounties() external view returns (BountyMetadata[] memory) {
        
        BountyMetadata[] memory bountyArray = new BountyMetadata[](4);

        for (uint32 i = 0; i < 4; i++) {
            bountyArray[i] = BountyMetadata({
                stablePay: i * 2000 ether,
                nativePay: i * 1000 ether,
                exchangeRate: 1 ether,
                nativeToken: 0x96B82B65ACF7072eFEb00502F45757F254c2a0D4,
                worker: address(0),
                recruiter: address(1),
                isClosed: false,
                deadline: block.timestamp + 60 days
            });
        }

        return bountyArray;
    }

}