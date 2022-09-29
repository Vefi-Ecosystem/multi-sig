pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/TransferHelpers.sol";
import "./MultiSig.sol";

contract MultiSigActions is Ownable {
  uint256 public fee;

  event MultiSigDeployed(address wallet, address[] signatories, uint256 requiredConfirmations);

  constructor(uint256 _fee) {
    fee = _fee;
  }

  function deployMultiSigWallet(address[] memory signatories, uint256 requiredConfirmations) external payable returns (address multiSigWallet) {
    require(msg.value >= fee, "fee");
    bytes memory bytecode = abi.encodePacked(type(MultiSig).creationCode, abi.encode(_msgSender(), signatories, requiredConfirmations));
    bytes32 salt = keccak256(abi.encodePacked(_msgSender(), signatories, requiredConfirmations, block.timestamp));

    assembly {
      multiSigWallet := create2(0, add(bytecode, 32), mload(bytecode), salt)
      if iszero(extcodesize(multiSigWallet)) {
        revert(0, 0)
      }
    }

    emit MultiSigDeployed(multiSigWallet, signatories, requiredConfirmations);
  }

  function setFee(uint256 _fee) external onlyOwner {
    fee = _fee;
  }

  function withdrawEther(address to) external onlyOwner {
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  receive() external payable {}
}
