pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMultiSig.sol";

contract MultiSig is AccessControl, Ownable, IMultiSig {
  bytes32 public soleOwnerRole = keccak256(abi.encodePacked("SOLE_OWNER_ROLE"));
  bytes32 public ownerRole = keccak256(abi.encodePacked("OWNER_ROLE"));
  uint256 public requiredConfirmations;

  Transaction[] public transactions;

  uint256 private currentIndex;

  modifier txExists(uint256 txIndex) {
    require(txIndex < transactions.length, "transaction_does_not_exist");
    _;
  }

  modifier notExecuted(uint256 txIndex) {
    Transaction memory transaction = transactions[txIndex];
    require(!transaction.isExecuted, "transaction_already_executed");
    _;
  }

  modifier hasRequiredConfirmations(uint256 txIndex) {
    Transaction memory transaction = transactions[txIndex];
    require(transaction.confirmations == requiredConfirmations, "not_enough_confirmations");
    _;
  }

  modifier doesNotHaveRequiredConfirmations(uint256 txIndex) {
    Transaction memory transaction = transactions[txIndex];
    require(transaction.confirmations < requiredConfirmations, "already_has_required_confirmations");
    _;
  }

  modifier executedByInitiator(uint256 txIndex) {
    Transaction memory transaction = transactions[txIndex];
    require(_msgSender() == transaction.initiator, "must_be_exceuted_by_initiator");
    _;
  }

  constructor(
    address soleOwner,
    address[] memory owners,
    uint256 _requiredConfirmations
  ) {
    require(soleOwner != address(0), "zero_address");
    require(owners.length > 0, "owners_required");
    require(
      _requiredConfirmations <= owners.length && _requiredConfirmations > 0,
      "confirmation_must_be_at_least_1_and_should_be_less_than_or_equal_to_number_of_owners"
    );
    requiredConfirmations = _requiredConfirmations;
    for (uint256 i = 0; i < owners.length; i++) {
      require(owners[i] != address(0), "zero_address");
      require(!hasRole(ownerRole, owners[i]), "already_granted_ownership");
      _grantRole(ownerRole, owners[i]);
    }
  }

  function allTransactions() public view returns (Transaction[] memory txs) {
    txs = transactions;
  }

  function initiateTransaction(
    address to,
    bytes memory data,
    uint256 value
  ) public {
    require(hasRole(ownerRole, _msgSender()) || hasRole(soleOwnerRole, _msgSender()), "only_signatory");
    Transaction memory transaction = Transaction({
      to: to,
      transactionIndex: currentIndex,
      initiator: _msgSender(),
      confirmations: 0,
      isExecuted: false,
      data: data,
      value: value
    });
    transactions.push(transaction);
    currentIndex = currentIndex + 1;
    emit TransactionInitiated(to, transaction.transactionIndex, _msgSender(), 0, false, data, value);
  }

  function confirmTransaction(uint256 txIndex) external txExists(txIndex) doesNotHaveRequiredConfirmations(txIndex) notExecuted(txIndex) {
    require(hasRole(ownerRole, _msgSender()) || hasRole(soleOwnerRole, _msgSender()), "only_signatory");
    Transaction storage transaction = transactions[txIndex];
    transaction.confirmations = transaction.confirmations + 1;
    emit TransactionConfirmed(txIndex, transaction.confirmations);
  }

  function executeTransaction(uint256 txIndex)
    external
    txExists(txIndex)
    hasRequiredConfirmations(txIndex)
    notExecuted(txIndex)
    executedByInitiator(txIndex)
  {
    Transaction storage transaction = transactions[txIndex];
    transaction.isExecuted = true;

    (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "transaction_failed");
    emit TransactionExecuted(txIndex);
  }

  function transferEther(address to) external payable {
    initiateTransaction(to, "", msg.value);
  }

  receive() external payable {}
}
