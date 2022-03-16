pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
//import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

//contract MemeContest is ERC1155PresetMinterPauser {
//}
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";



contract Contest is ERC1155, IERC1155Receiver {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public constant EPOQUE_LENGTH = 100;
    uint256 public _nextEpoque;
    bool public submissionsOpen;

    //mapping(uint256 => mapping(uint8 )) public _urls;

    struct Submission {
        string url;
        uint8 place;
        mapping (address => uint) stakedAmounts;
        address[] stakedAddresses;
    }
    mapping (uint256 => Submission) _submissions; 
    mapping (uint256 => uint256) _stakes; 

    //uint256[]  _stakes; 
    uint256[] _unjudged;
    uint256 _totalStaked;

    constructor() ERC1155("https://game.example/api/item/{id}.json") {
        _mint(msg.sender, 0, 10**18, ""); //token 0 is points
        _tokenIds.increment();
        _nextEpoque = _epoque() + EPOQUE_LENGTH;
        submissionsOpen = true;
    }

   function submit( string calldata url) public returns (uint256) {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        
        _submissions[id].url = url;
        _submissions[id].place = 0;

        _unjudged.push(id);
        
        _mint(msg.sender, id, 1, ""); //Send their NFT
        _mint(msg.sender, 0, 10, ""); //And 10 points to spend

        return id;
    }

    function stake(uint targetId, uint amount) public {
        safeTransferFrom( _msgSender(), address(this), 0, amount, "");
        _submissions[targetId].stakedAmounts[_msgSender()] += amount;
        _submissions[targetId].stakedAddresses.push(_msgSender());
        _stakes[targetId]+= amount;
        _totalStaked += amount;
    }

    function judge(uint targetId, uint8 place) public {
        _submissions[targetId].place = place;
    }


    function getUrl(uint256 id) public view returns (string memory) {
        string memory url = string(abi.encodePacked('', _submissions[id].url));
        return url;
    }

    function getPlace(uint256 id) public view returns (uint ) {
        /*
        string memory place= string(abi.encodePacked('', _submissions[id].place));
        return place;
        */
        return _submissions[id].place;
    }


    function _epoque() public view returns (uint256 ) {
        return block.timestamp/EPOQUE_LENGTH;
    }


 
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        
        console.logBytes( data);
        console.log( data.length);
        string memory str = string(data);
        console.log( str);
        uint256 tokenId = 40;

        console.log( operator, from, id, value );
        require(keccak256(abi.encode(_submissions[tokenId].url)) != keccak256(abi.encode("")), "Must specify a valid tokenId");

        return this.onERC1155Received.selector;

    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view override returns (bytes4) {
        console.log(operator, from);
        return this.onERC1155BatchReceived.selector;
    }


    function _quicksort(int left, int right) internal {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = _stakes[_unjudged[uint(left + (right - left) / 2)]];
        //  [5,3,4,6,2,4,9,5,6,3,1,1];
        while (i <= j) {
            while (_unjudged[uint(i)] < pivot) i++;
            while (pivot < _unjudged[uint(j)]) j--;
            if (i <= j) {
                (_stakes[_unjudged[uint(i)]], _stakes[_unjudged[uint(j)]]) = (_stakes[_unjudged[uint(j)]], _stakes[_unjudged[uint(i)]]);
                i++;
                j--;
            }
        }
        if (left < j)
            _quicksort( left, j);
        if (i < right)
            _quicksort( i, right);
    }    

    /*
    function _quicksort(uint[] storage arr, int left, int right) internal {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        //  [5,3,4,6,2,4,9,5,6,3,1,1];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            _quicksort(arr, left, j);
        if (i < right)
            _quicksort(arr, i, right);
    }
    */
}
