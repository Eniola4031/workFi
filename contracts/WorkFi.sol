//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IWorkFi.sol";
import "./YieldLogic.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ISuperfluid, ISuperfluidToken } 
    from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IInstantDistributionAgreementV1 } 
    from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import { IDAv1Library } 
    from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";

contract WorkFi is IWorkFi, YieldLogic {

    using IDAv1Library for IDAv1Library.InitData;

    struct Bounty {
 
        uint128 stablePay;
        uint128 nativePay;
        uint96 nativePrice; // 1 NT price in stablecoin
        ISuperfluidToken nativeToken; // NT contract address

        address worker;
        address recruiter;
        bool isClosed;
        uint256 deadline; // In seconds since Unix Epoch

        mapping(address => uint128) investors;
    }

    // Polygon Mumbai Addresses
    ISuperfluidToken FDAI =  ISuperfluidToken(0x15F0Ca26781C3852f8166eD2ebce5D18265cceb7);
    IDAv1Library.InitData internal idaLib = IDAv1Library.InitData(
            ISuperfluid(0xEB796bdb90fFA0f28255275e16936D25d3418603), 
            IInstantDistributionAgreementV1(0x804348D4960a61f2d5F9ce9103027A3E849E09b8)
    );

    uint32 internal totalBounties;
    mapping(uint32 => Bounty) public bounties;

    // Access Controls
    modifier onlyRecruiter(uint32 bountyId) {
        require(msg.sender == bounties[bountyId].recruiter);
        _;
    }

    modifier onlyWorker(uint32 bountyId) {
        require(msg.sender == bounties[bountyId].worker);
        _;
    }

    function acceptWorker(uint32 bountyId, address worker) external onlyRecruiter(bountyId) {
        require(bounties[bountyId].worker == address(0), 'A worker has already been accepted');
        bounties[bountyId].worker = worker;
    }

    function createBounty(
        uint128 stablePay, 
        uint128 nativePay, 
        uint96 nativePrice, 
        ISuperfluidToken nativeToken, 
        uint256 deadline
    ) external {

        Bounty storage newBounty = bounties[totalBounties];

        newBounty.stablePay = stablePay;
        newBounty.nativePay = nativePay;
        newBounty.nativePrice = nativePrice;
        newBounty.nativeToken = nativeToken;
        newBounty.recruiter = msg.sender;
        newBounty.deadline = deadline;

        ERC20(address(FDAI)).transfer(address(this), stablePay);
        ERC20(address(nativeToken)).transfer(address(this), nativePay);

        idaLib.createIndex(FDAI, totalBounties);
        idaLib.updateSubscriptionUnits(FDAI, totalBounties, msg.sender, stablePay);

        totalBounties++;
    }

    function invest(uint32 bountyId, uint128 stableAmount) external {

        Bounty storage bounty = bounties[bountyId];

        // 1. Transfer approved DAI
        ERC20(address(FDAI)).transferFrom(msg.sender, address(this), stableAmount);

        uint128 investAmount = bounty.investors[msg.sender] + stableAmount;

        // 2. Update Superfluid indices
        idaLib.updateSubscriptionUnits(bounty.nativeToken, bountyId, msg.sender, investAmount);
        idaLib.updateSubscriptionUnits(FDAI, bountyId, msg.sender, investAmount / bounty.nativePrice);

        // 3. Update contract state
        bounty.investors[msg.sender] = investAmount;
        bounty.stablePay += stableAmount;
        bounty.nativePay -= (stableAmount / bounty.nativePrice); // TODO: Test precision error

    }

    function acceptPayment(uint32 bountyId) external onlyWorker(bountyId) {
        _payBounty(bountyId);
    }

    function closeBounty(uint32 bountyId) external {
        Bounty storage b = bounties[bountyId];

        require(block.timestamp > b.deadline);

        if(b.worker == address(0)) {
            _payBounty(bountyId);
            return;
        }

        idaLib.distribute(FDAI, bountyId, b.stablePay);
        b.isClosed = true;
    }

    function _payBounty(uint32 bountyId) internal {
        Bounty storage b = bounties[bountyId];

        ERC20(address(FDAI)).transfer(msg.sender, b.stablePay);
        
        idaLib.updateSubscriptionUnits(b.nativeToken, bountyId, msg.sender, b.nativePay);
        idaLib.distribute(b.nativeToken, bountyId, b.nativePay);
        
        b.isClosed = true;
    }

    function getInvestment(uint32 bountyId) external view returns (uint128) {
        return bounties[bountyId].investors[msg.sender];
    }

    function getBounty(uint32 bountyId) external view returns (BountyMetadata memory) {
        Bounty storage b = bounties[bountyId];

        return BountyMetadata({
            stablePay: b.stablePay,
            nativePay: b.nativePrice,
            nativePrice: b.nativePrice, // 1 NT price in stablecoin
            nativeToken: address(b.nativeToken), // NT contract address
            worker: b.worker,
            recruiter: b.recruiter,
            isClosed: b.isClosed,
            deadline: b.deadline
        });
    }

    function getBounties() external view returns (BountyMetadata[] memory) {
        BountyMetadata[] memory bountyArray = new BountyMetadata[](totalBounties);

        for (uint32 i = 0; i < totalBounties; i++) {
            Bounty storage b = bounties[i];

            bountyArray[i] = BountyMetadata({
                stablePay: b.stablePay,
                nativePay: b.nativePrice,
                nativePrice: b.nativePrice, // 1 NT price in stablecoin
                nativeToken: address(b.nativeToken), // NT contract address
                worker: b.worker,
                recruiter: b.recruiter,
                isClosed: b.isClosed,
                deadline: b.deadline
            });
        }

        return bountyArray;
    }

}