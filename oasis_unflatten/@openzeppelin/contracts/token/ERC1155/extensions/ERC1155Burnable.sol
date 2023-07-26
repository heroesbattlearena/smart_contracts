// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155, Ownable {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() ||
                isApprovedForAll(account, _msgSender()) ||
                _msgSender() == admin(),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.4;

contract HeroesBattleArena is ERC1155, Ownable, ERC1155Burnable {
    struct PartWithPrice {
        string name;
        uint256 price;
        string herotype;
    }

    DemoOracle demoOracle;
    string public name;

    mapping(uint256 => PartWithPrice) allParts;
    uint256[] public partIds;

    uint256 public earlyHeroesSupply;
    uint256 public olympHeroesSupply;
    uint256 public nordHeroesSupply;
    uint256 public freeStonesSupply;

    uint256 public earlyHeroesNumber;
    uint256 public olympHeroesNumber;
    uint256 public nordHeroesNumber;

    bool reentrancyGuardFlag = false;

    constructor(string memory _url, IStdReference _ref) ERC1155(_url) {
        name = "HEROES BATTLE ARENA";
        demoOracle = new DemoOracle(_ref);
        earlyHeroesSupply = 70000;
        olympHeroesSupply = 50000;
        nordHeroesSupply = 30000;
        freeStonesSupply = 6;
    }

    function addPart(
        string memory nftName,
        uint256 id,
        uint256 price,
        string memory herotype
    ) public onlyAdmin {
        PartWithPrice storage newPart = allParts[id];
        newPart.name = nftName;
        newPart.herotype = herotype;
        newPart.price = price;
        partIds.push(id);
    }

    function getPartById(uint256 id)
        public
        view
        returns (string memory, uint256)
    {
        PartWithPrice storage s = allParts[id];
        return (s.name, s.price);
    }

    function getPartByName(string memory _name) public view returns (uint256) {
        for (uint256 i = 0; i <= partIds.length; i++) {
            PartWithPrice storage s = allParts[i];
            if (
                keccak256(abi.encodePacked(s.name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return s.price;
            }
        }
        return 0;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(string memory _name, uint256 amount) public payable {
        require(!reentrancyGuardFlag, "Reentrancy Guard Activated");
        reentrancyGuardFlag = true;
        uint256 resultPrice = getPrice();
        for (uint256 i = 0; i <= partIds.length; ++i) {
            PartWithPrice storage s = allParts[i];
            if (
                keccak256(abi.encodePacked(s.name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                if (
                    keccak256(abi.encodePacked((s.herotype))) ==
                    keccak256(abi.encodePacked(("Free")))
                ) {
                    require(
                        balanceOf(msg.sender, i) + amount < freeStonesSupply,
                        "You already have maximum free stone."
                    );
                    require(
                        s.price * amount == msg.value,
                        "Value sent is not correct"
                    );
                    _mint(msg.sender, i, amount, "0x0");
                    payable(owner()).transfer(msg.value);
                    continue;
                } else {
                    if (msg.sender != owner()) {
                        uint256 price = (s.price * 10**18) / resultPrice;
                        if (price < 1) price = 1;
                        require(
                            price * amount <= msg.value,
                            "Value sent is not correct"
                        );
                    }
                    if (
                        keccak256(abi.encodePacked((s.herotype))) ==
                        keccak256(abi.encodePacked(("Early")))
                    ) {
                        require(
                            earlyHeroesNumber < earlyHeroesSupply,
                            "There is no supply, right now."
                        );
                        _mint(msg.sender, i, amount, "0x0");
                        payable(owner()).transfer(msg.value);
                        earlyHeroesNumber++;
                    } else if (
                        keccak256(abi.encodePacked((s.herotype))) ==
                        keccak256(abi.encodePacked(("Olymp")))
                    ) {
                        require(
                            earlyHeroesNumber < olympHeroesSupply,
                            "There is no supply, right now."
                        );
                        _mint(msg.sender, i, amount, "0x0");
                        payable(owner()).transfer(msg.value);
                        olympHeroesNumber++;
                    } else if (
                        keccak256(abi.encodePacked((s.herotype))) ==
                        keccak256(abi.encodePacked(("Nord")))
                    ) {
                        require(
                            nordHeroesNumber < nordHeroesSupply,
                            "There is no supply, right now."
                        );
                        _mint(msg.sender, i, amount, "0x0");
                        payable(owner()).transfer(msg.value);
                        nordHeroesNumber++;
                    } else {
                        _mint(msg.sender, i, amount, "0x0");
                        payable(owner()).transfer(msg.value);
                    }
                }
            }
        }
        reentrancyGuardFlag = false;
    }

    function changeEarlySupply(uint256 supply) public onlyOwner {
        earlyHeroesSupply = supply;
    }

    function changeOlympSupply(uint256 supply) public onlyOwner {
        olympHeroesSupply = supply;
    }

    function changeNordSupply(uint256 supply) public onlyOwner {
        nordHeroesSupply = supply;
    }

    function changeFreeSupply(uint256 supply) public onlyOwner {
        freeStonesSupply = supply;
    }

    function getPrice() public view returns (uint256) {
        return demoOracle.getPrice();
    }

    function withdrawBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
