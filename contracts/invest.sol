// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract workFi {

    address recruiter;
    address worker;
    uint256 nativeTokenAmt;
    uint256 stableCurrency;
    address nativeTokenAddr;
    uint deadline;
    bool startJob;
    bool completeJob;



    modifier onlyRecruiter{
        require(msg.sender == recruiter);
        _;
        
    }
    modifier onlyWorker{
        require(msg.sender == worker);
        _;
    }

    mapping(address => uint256) investorToInvested;
    /**
     * @dev Store value in variable
     * @param _worker value to store
     */
    function acceptWorker(address _worker) onlyRecruiter public {
    }

   
    function investor(uint256 _stableCoin) public {
    }
    function acceptPayment() onlyWorker public{

    }
    function depositToken()public{

    }
    function closeBounty()public{

    }
}