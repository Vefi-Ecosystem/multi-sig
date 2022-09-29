pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMultiSig.sol";

contract MultiSig is AccessControl, Ownable, IMultiSig {
  bytes32 public soleOwnerRole = keccak256(abi.encodePacked("SOLE_OWNER_ROLE"));
  bytes32 public ownerRole = keccak256(abi.encodePacked("OWNER_ROLE"));
  uint256 public requiredConfirmations;

  mapping(address => mapping(uint256 => bool)) public confirmations;

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
    require(!confirmations[_msgSender()][txIndex], "you_have_already_confirmed_this_transaction");
    Transaction storage transaction = transactions[txIndex];
    transaction.confirmations = transaction.confirmations + 1;
    confirmations[_msgSender()][txIndex] = true;
    emit TransactionConfirmed(txIndex, transaction.confirmations);
  }

  function revokeConfirmation(uint256 txIndex) external txExists(txIndex) notExecuted(txIndex) {
    require(hasRole(ownerRole, _msgSender()) || hasRole(soleOwnerRole, _msgSender()), "only_signatory");
    require(confirmations[_msgSender()][txIndex], "you_did_not_confirm_this_transaction");
    Transaction storage transaction = transactions[txIndex];
    transaction.confirmations = transaction.confirmations - 1;
    confirmations[_msgSender()][txIndex] = false;
    emit ConfirmationRevoked(txIndex, transaction.confirmations);
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

  function addSignatory(address account) external {
    require(hasRole(soleOwnerRole, _msgSender()), "only_sole_owner");
    require(!hasRole(ownerRole, account), "already_a_signatory");
    _grantRole(ownerRole, account);
  }

  function removeSignatory(address account) external {
    require(hasRole(soleOwnerRole, _msgSender()), "only_sole_owner");
    require(hasRole(ownerRole, account), "not_a_signatory");
    _revokeRole(ownerRole, account);
  }

  receive() external payable {}
}
