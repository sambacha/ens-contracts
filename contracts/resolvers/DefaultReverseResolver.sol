pragma solidity >=0.8.4;

import "../registry/ENS.sol";
import "../registry/ReverseRegistrar.sol";

error NotAuthorised();

/**
 * @dev Provides a default implementation of a resolver for reverse records,
 * which permits only the owner to update it.
 */
contract DefaultReverseResolver {
    // namehash('addr.reverse')
    bytes32 constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    ENS public ens;
    mapping(bytes32 => string) public name;
    address immutable trustedReverseRegistrar;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     */
    constructor(ENS ensAddr) {
        ens = ensAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar registrar = ReverseRegistrar(
            ens.owner(ADDR_REVERSE_NODE)
        );
        trustedReverseRegistrar = address(registrar);
        if (address(registrar) != address(0x0)) {
            registrar.claim(msg.sender);
        }
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function isAuthorised(bytes32 node) internal view returns (bool) {
        if (msg.sender == trustedReverseRegistrar) {
            return true;
        }
        address owner = ens.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    /**
     * @dev Sets the name for a node.
     * @param node The node to update.
     * @param _name The name to set.
     */
    function setName(bytes32 node, string memory _name) public {
        if (!isAuthorised(node)) {
            revert NotAuthorised();
        }
        name[node] = _name;
    }
}