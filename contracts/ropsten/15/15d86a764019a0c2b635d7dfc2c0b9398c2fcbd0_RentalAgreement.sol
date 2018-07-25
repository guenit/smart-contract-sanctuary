pragma solidity ^0.4.24; library SafeMath { function mul(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a * b; assert(a == 0 || c / a == b); return c; } function div(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a / b; return c; } function sub(uint256 a, uint256 b) internal pure returns (uint256) { assert(b <= a); return a - b; } function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; assert(c >= a && c >= b); return c; } } interface notifier { function deposit(address user, uint256 amount, uint256 timestamp) external; function withdraw(address user, uint256 amount, uint256 timestamp) external; function rentModified(address user, uint256 amount, uint256 timestamp) external; function ticket(address user, bool ticketOpen, uint256 timestamp) external; function approved(address user, uint256 timestamp) external; function dispute(address user, bool ongGoing, uint256 timestamp) external; function admin(address user) external returns (bool); } contract RentalAgreement { using SafeMath for uint256; notifier public Notifier; address public landlord; address public tenant; uint256 public rent; bool public agreementApproved; uint256 public lockedAmount; uint256 public availableAmount; bool public ticketOpen; bool public onGoingDispute; address public disputeStartedBy; uint256 public lastDepositAmount; uint256 public lastWithdrawalAmount; /*-----Rental Agreement Clauses-----*/ /*General*/ uint256 public selectedPropertyID = 1; string public selectedCountry =&#39;CAN&#39;; uint256 public selectedStateID = 0; uint256 public dateLeaseStarts = 1532330968; uint256 public leaseDateSelected = 1; uint256 public dateLeaseEnds = 1532577600; uint256 public renewalSelected = 0; /*Property*/ uint256 public selectedAccessToParking = 1; /*Parties*/ uint256 public selectedOccupantsOptions = 1; /*Terms*/ uint256 public selectedRentFrequency = 3; uint256 public rentAgreed = 560000000000000000; uint256 public paymentDateDay = 1; uint256 public paymentDateMonth = 0; uint256 public selectedincrementNotice = 1; uint256 public daysNoticeBeforeIncreasingRent = 0; uint256 public selectedPetsAllowance = 1; uint256 public selectedSmokingAllowance = 1; uint256 public selectedLatePayment = 1; uint256 public latePaymentAmount = 0; uint256 public selectedUtilitiesDetails = 1; uint256 public electricity = 0; uint256 public water_sewer = 0; uint256 public internet = 0; uint256 public cable = 0; uint256 public telephone = 0; uint256 public naturalGas = 0; uint256 public heatingOil_propane = 0; uint256 public garbageCollection = 0; uint256 public alarm_securitySystem = 0; /*Final details*/ uint256 public selectedDisputeResolution = 1; uint256 public selectedDisputeResolutionCost = 0; uint256 public selectedAdditionalClause = 2; event Approved(address user, uint256 timestamp); event Deposit(address user, uint256 amount, uint256 timestamp); event Withdraw(address user, uint256 amount, uint256 timestamp); event RentModified(address user, uint256 amount, uint256 timestamp); event Ticket(address user, bool open, uint256 timestamp); event Dispute(address user, bool ongGoing, uint256 timestamp); constructor() public { Notifier = notifier(0xa24e04248442EB2779d014ECa85dBE9dfaB42967); landlord = msg.sender; /*Landlord&#39;s address*/ tenant = 0x00de09b417fe66e934754fefb87c9695a6e2e32b; /*Tenant&#39;s address*/ rent = 560000000000000000; /*rent amount*/ } /*Tenant approves this this agreement*/ function approveAgreement() public { require(msg.sender == tenant); agreementApproved = true; Notifier.approved(msg.sender, now); emit Approved(msg.sender, now); } /*Tenant deposits the rent*/ function deposit() payable rentalAgreementApproved public { uint256 amount = msg.value; lastDepositAmount = amount; if(ticketOpen){ lockedAmount = lockedAmount.add(amount); }else{ availableAmount = availableAmount.add(amount); } Notifier.deposit(msg.sender, amount, now); emit Deposit(msg.sender, amount, now); } function () payable public { deposit(); } /*Withdraw the money paid*/ function withdraw() rentalAgreementApproved public { require(msg.sender == landlord); uint256 amount = availableAmount; availableAmount = 0; lastWithdrawalAmount = amount; msg.sender.transfer(amount); Notifier.withdraw(msg.sender, amount, now); emit Withdraw(msg.sender, amount, now); } /*Increase/Decrease the rent*/ function modifyRent(uint256 newRent) rentalAgreementApproved public { require(msg.sender == landlord); rent = newRent; Notifier.rentModified(msg.sender, rent, now); emit RentModified(msg.sender, rent, now); } /*Open a ticket*/ function openTicket() rentalAgreementApproved public { require(msg.sender == tenant); require(!ticketOpen); ticketOpen = true; Notifier.ticket(msg.sender, ticketOpen, now); emit Ticket(msg.sender, ticketOpen, now); } /*Close the ticket*/ function closeTicket() public { require(msg.sender == tenant || Notifier.admin(msg.sender)); require(ticketOpen); ticketOpen = false; uint256 amount = lockedAmount; lockedAmount = 0; availableAmount = availableAmount.add(amount); Notifier.ticket(msg.sender, ticketOpen, now); emit Ticket(msg.sender, ticketOpen, now); } /*Start dispute*/ function startDispute() rentalAgreementApproved public { require(!onGoingDispute); require(Notifier.admin(msg.sender) || msg.sender == landlord || msg.sender == tenant); disputeStartedBy = msg.sender; onGoingDispute = true; Notifier.dispute(msg.sender, onGoingDispute, now); emit Dispute(msg.sender, onGoingDispute, now); } /*End dispute*/ function endDispute() public { require(onGoingDispute); require(msg.sender == disputeStartedBy || Notifier.admin(msg.sender)); onGoingDispute = false; Notifier.dispute(msg.sender, onGoingDispute, now); emit Dispute(msg.sender, onGoingDispute, now); } function viewContractState() public view returns(uint256,uint256,uint256,bool,bool,address,uint256,uint256){ return (rent, lockedAmount, availableAmount, ticketOpen, onGoingDispute, disputeStartedBy, lastDepositAmount, lastWithdrawalAmount); } function viewMostRelevantClauses() public view returns(uint256,string,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){ return (selectedPropertyID, selectedCountry, selectedStateID, selectedRentFrequency, paymentDateDay, paymentDateMonth, dateLeaseStarts, leaseDateSelected, dateLeaseEnds, renewalSelected); } function viewFirstLotOfClauses() public view returns(uint256,string,uint256,uint256,uint256,uint256,uint256,uint256){ return (selectedPropertyID, selectedCountry, selectedStateID, dateLeaseStarts, leaseDateSelected, dateLeaseEnds, renewalSelected, selectedAccessToParking); } function viewSecondLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){ return (selectedOccupantsOptions, selectedRentFrequency, rentAgreed, paymentDateDay, paymentDateMonth, selectedincrementNotice, daysNoticeBeforeIncreasingRent, selectedPetsAllowance); } function viewThirdLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){ return (selectedSmokingAllowance, selectedLatePayment, latePaymentAmount, selectedUtilitiesDetails, electricity, water_sewer, internet, cable); } function viewFourthLotOfClauses() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){ return (telephone, naturalGas, heatingOil_propane, garbageCollection, alarm_securitySystem, selectedDisputeResolution, selectedDisputeResolutionCost, selectedAdditionalClause); } modifier rentalAgreementApproved { require(agreementApproved); _; } }