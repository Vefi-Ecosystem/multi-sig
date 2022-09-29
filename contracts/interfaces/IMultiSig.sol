pragma solidity ^0.8.0;

interface IMultiSig {
  struct Transaction {
    address to;
    uint256 transactionIndex;
    address initiator;
    uint256 confirmations;
    bool isExecuted;
    bytes data;
    uint256 value;
  }

  function transactions(uint256)
    external
    view
    returns (
      address,
      uint256,
      address,
      uint256,
      bool,
      bytes memory,
      uint256
    );

  function allTransactions() external view returns (Transaction[] memory);

  event TransactionInitiated(
    address to,
    uint256 transactionIndex,
    address initiator,
    uint256 confirmations,
    bool isExecuted,
    bytes data,
    uint256 value
  );
  event TransactionConfirmed(uint256 transactionIndex, uint256 confirmations);
  event TransactionExecuted(uint256 transactionIndex);
  event ConfirmationRevoked(uint256 transactionIndex, uint256 confirmations);
}
