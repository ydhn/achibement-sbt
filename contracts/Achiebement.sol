// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC5633.sol";

contract Achiebement is ERC1155, ERC1155Burnable, Ownable, ERC5633 {
    address private _signer;

    constructor(string memory tokenURI) ERC1155(tokenURI) ERC5633() {}

    function setSigner(address signer) public onlyOwner {
        _signer = signer;
    }

    function recover(uint256[] calldata ids, uint256[] calldata amounts, uint256[] calldata holdings, bytes memory _signature)
    private
    view
    returns (address)
    {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(msg.sender, ids, amounts, holdings))), _signature);
    }

    function mint(uint256[] calldata ids, uint256[] calldata amounts, uint256[] calldata holdings, bytes memory _signature)
    external
    {
        require(ids.length == amounts.length, "Invalid arguments");
        require(_signer == recover(ids, amounts, holdings, _signature), "Invalid signature");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(balanceOf(msg.sender, id) == holdings[i], "Signature expired");
            if (!isSoulbound(id)) _setSoulbound(id, true);
        }
        _mintBatch(msg.sender, ids, amounts, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function setSoulbound(uint256 id, bool soulbound)
    public
    onlyOwner
    {
        _setSoulbound(id, soulbound);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, ERC5633)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC5633)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function getInterfaceId() public view returns (bytes4) {
        return type(IERC5633).interfaceId;
    }
}
