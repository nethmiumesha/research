pragma solidity 0.8.12;
import "./VaultManagerStorage.sol";
abstract contract VaultManagerERC721 is IERC721MetadataUpgradeable, VaultManagerStorage {
    using SafeERC20 for IERC20;
    using Address for address;
    string public name;
    string public symbol;
    modifier onlyApprovedOrOwner(address caller, uint256 vaultID) {
        if (!_isApprovedOrOwner(caller, vaultID)) revert NotApproved();
        _;
    }
    function getControlledVaults(address spender) external view returns (uint256[] memory, uint256) {
        uint256 arraySize = vaultIDCount;
        uint256[] memory vaultsControlled = new uint256[](arraySize);
        address owner;
        uint256 count;
        for (uint256 i = 1; i <= arraySize; i++) {
            owner = _owners[i];
            if (spender == owner || _getApproved(i) == spender || _operatorApprovals[owner][spender] == 1) {
                vaultsControlled[count] = i;
                count += 1;
            }
        }
        return (vaultsControlled, count);
    }
    function isApprovedOrOwner(address spender, uint256 vaultID) external view returns (bool) {
        return _isApprovedOrOwner(spender, vaultID);
    }
    function tokenURI(uint256 vaultID) external view returns (string memory) {
        if (!_exists(vaultID)) revert NonexistentVault();
        uint256 temp = vaultID;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (vaultID != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(vaultID % 10)));
            vaultID /= 10;
        }
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, string(buffer))) : "";
    }
    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }
    function ownerOf(uint256 vaultID) external view returns (address) {
        return _ownerOf(vaultID);
    }
    function approve(address to, uint256 vaultID) external {
        address owner = _ownerOf(vaultID);
        if (to == owner) revert ApprovalToOwner();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotApproved();
        _approve(to, vaultID);
    }
    function getApproved(uint256 vaultID) external view returns (address) {
        if (!_exists(vaultID)) revert NonexistentVault();
        return _getApproved(vaultID);
    }
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator] == 1;
    }
    function transferFrom(
        address from,
        address to,
        uint256 vaultID
    ) external onlyApprovedOrOwner(msg.sender, vaultID) {
        _transfer(from, to, vaultID);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 vaultID
    ) external {
        safeTransferFrom(from, to, vaultID, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 vaultID,
        bytes memory _data
    ) public onlyApprovedOrOwner(msg.sender, vaultID) {
        _safeTransfer(from, to, vaultID, _data);
    }
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IVaultManager).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    function _ownerOf(uint256 vaultID) internal view returns (address owner) {
        owner = _owners[vaultID];
        if (owner == address(0)) revert NonexistentVault();
    }
    function _getApproved(uint256 vaultID) internal view returns (address) {
        return _vaultApprovals[vaultID];
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 vaultID,
        bytes memory _data
    ) internal {
        _transfer(from, to, vaultID);
        if (!_checkOnERC721Received(from, to, vaultID, _data)) revert NonERC721Receiver();
    }
    function _exists(uint256 vaultID) internal view returns (bool) {
        return _owners[vaultID] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 vaultID) internal view returns (bool) {
        address owner = _ownerOf(vaultID);
        return (spender == owner || _getApproved(vaultID) == spender || _operatorApprovals[owner][spender] == 1);
    }
    function _mint(address to) internal returns (uint256 vaultID) {
        if (whitelistingActivated && (isWhitelisted[to] != 1 || isWhitelisted[msg.sender] != 1))
            revert NotWhitelisted();
        if (to == address(0)) revert ZeroAddress();
        unchecked {
            vaultIDCount += 1;
            _balances[to] += 1;
        }
        vaultID = vaultIDCount;
        _owners[vaultID] = to;
        emit Transfer(address(0), to, vaultID);
        if (!_checkOnERC721Received(address(0), to, vaultID, "")) revert NonERC721Receiver();
    }
    function _burn(uint256 vaultID) internal {
        address owner = _ownerOf(vaultID);
        _approve(address(0), vaultID);
        unchecked {
            _balances[owner] -= 1;
        }
        delete _owners[vaultID];
        delete vaultData[vaultID];
        emit Transfer(owner, address(0), vaultID);
    }
    function _transfer(
        address from,
        address to,
        uint256 vaultID
    ) internal {
        if (_ownerOf(vaultID) != from) revert NotApproved();
        if (to == address(0)) revert ZeroAddress();
        if (whitelistingActivated && isWhitelisted[to] != 1) revert NotWhitelisted();
        _approve(address(0), vaultID);
        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[vaultID] = to;
        emit Transfer(from, to, vaultID);
    }
    function _approve(address to, uint256 vaultID) internal {
        _vaultApprovals[vaultID] = to;
        emit Approval(_ownerOf(vaultID), to, vaultID);
    }
    function _setApprovalForAll(
        address approver,
        address operator,
        bool approved
    ) internal {
        if (operator == approver) revert ApprovalToCaller();
        uint256 approval = approved ? 1 : 0;
        _operatorApprovals[approver][operator] = approval;
        emit ApprovalForAll(approver, operator, approved);
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 vaultID,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(msg.sender, from, vaultID, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NonERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}