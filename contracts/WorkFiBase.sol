//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IWorkFi.sol";
//import "./YieldLogic.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ISuperfluid, ISuperfluidToken } 
    from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IInstantDistributionAgreementV1 } 
    from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import { IDAv1Library } 
    from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";

abstract contract WorkFiBase is IWorkFi /*, YieldLogic*/ {

    using IDAv1Library for IDAv1Library.InitData;

    struct Bounty {
 
        uint128 stablePay;
        uint128 nativePay;
        uint96 exchangeRate; // Amount of native token 1 DAI can buy
        ISuperfluidToken nativeToken;

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

    uint32 internal totalCount; // Number of open bounties
    uint32 internal closedCount; // Number of closed bounties
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

    modifier onlyInvestor(uint32 bountyId){
             require(msg.sender == bounties[bountyId].investor);
        _;

    }

    function acceptWorker(
        uint32 bountyId, 
        address worker
    ) external override onlyRecruiter(bountyId) {

        require(bounties[bountyId].worker == address(0), 'A worker has already been accepted');
        bounties[bountyId].worker = worker;

    }

    function createBounty(
        uint128 stablePay, 
        uint128 nativePay, 
        uint96 exchangeRate, 
        address nativeToken, 
        uint256 deadline
    ) external override returns (uint32) {

        Bounty storage newBounty = bounties[totalCount];

        newBounty.stablePay = stablePay;
        newBounty.nativePay = nativePay;
        newBounty.exchangeRate = exchangeRate;
        newBounty.nativeToken = ISuperfluidToken(nativeToken);
        newBounty.recruiter = msg.sender;
        newBounty.deadline = deadline;

        ERC20(address(FDAI)).transfer(address(this), stablePay);
        ERC20(address(nativeToken)).transfer(address(this), nativePay);

        idaLib.createIndex(FDAI, totalCount);
        idaLib.updateSubscriptionUnits(FDAI, totalCount, msg.sender, stablePay);

        return totalCount++;
    }

    function invest(uint32 bountyId, uint128 stableAmount) external override {

        Bounty storage b = bounties[bountyId];

        // 1. Transfer approved DAI
        ERC20(address(FDAI)).transferFrom(msg.sender, address(this), stableAmount);

        uint128 investAmount = b.investors[msg.sender] + stableAmount;

        // 2. Update Superfluid indices
        idaLib.updateSubscriptionUnits(b.nativeToken, bountyId, msg.sender, investAmount);
        idaLib.updateSubscriptionUnits(FDAI, bountyId, 
            msg.sender, _stableToNative(stableAmount, b.exchangeRate));

        // 3. Update contract state
        b.investors[msg.sender] = investAmount;
        b.stablePay += stableAmount;
        b.nativePay -= _stableToNative(stableAmount, b.exchangeRate); // TODO: Test precision error

    }

    function acceptPayment(uint32 bountyId) external override onlyWorker(bountyId) {
        _payBounty(bountyId);
    }

    function closeBounty(uint32 bountyId) external override {
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

    function _stableToNative(uint128 stableAmount, uint96 exchangeRate) internal pure returns (uint128) {
        return (stableAmount / 1 ether) * exchangeRate;
    }

    //allow investors to withdraw their incentives per APY
        function withdraw(uint256 amount) external returns(bool) onlyInvestor(bountyId){
            require(investors[msg.sender] > 0,"only investors can withdraw");
           uint256 x = bounty.investors[msg.sender];
            uint256 duration = bounty.timestamps[msg.sender];
           uint256 reward = x * duration * APR / (num of seconds in a year);
            (bool sent,) = payable(msg.sender).call{value: reward}("");
            require(sent,"reward not sent:failed transaction");
                return true;

    }


}