//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./WorkFiBase.sol";

contract WorkFi is WorkFiBase {

    function getInvestment(uint32 bountyId) external view override returns (uint128) {
        return bounties[bountyId].investors[msg.sender];
    }

    function getBounty(uint32 bountyId) external view override returns (BountyMetadata memory) {
        Bounty storage b = bounties[bountyId];

        return BountyMetadata({
            stablePay: b.stablePay,
            nativePay: b.nativePay,
            exchangeRate: b.exchangeRate,
            nativeToken: address(b.nativeToken),
            worker: b.worker,
            recruiter: b.recruiter,
            isClosed: b.isClosed,
            deadline: b.deadline
        });
    }

    function getOpenBounties() external view override returns (uint32[] memory) {
        uint32 openCount = totalCount - closedCount;
        uint32[] memory ids = new uint32[](openCount);

        uint32 ctr = 0;
        for (uint32 i = 0; i < totalCount; i++) {
            Bounty storage b = bounties[i];

            if (!b.isClosed) {
                ids[ctr++] = i;
            }
        }

        return ids;
    }

    function getOpenBounties(address recruiter) external view returns (uint32[] memory) {
        uint32 openCount = totalCount - closedCount;
        uint32[] memory ids = new uint32[](openCount);

        uint32 ctr = 0;
        for (uint32 i = 0; i < totalCount; i++) {
            Bounty storage b = bounties[i];

            if (!b.isClosed && b.recruiter == recruiter) {
                ids[ctr++] = i;
            }
        }

        return ids;
    }

    function getInvestedBounties(bool isOpen) external view returns (uint32[] memory) {
        uint32 openCount = totalCount - closedCount;
        uint32[] memory ids = new uint32[](openCount);

        uint32 ctr = 0;
        for (uint32 i = 0; i < totalCount; i++) {
            Bounty storage b = bounties[i];

            if (b.isClosed == !isOpen && b.investors[msg.sender] > 0) {
                ids[ctr++] = i;
            }
        }

        return ids;
    }
}