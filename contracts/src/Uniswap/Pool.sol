// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "solady/tokens/ERC20.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";

interface IPool {
    function initialize(string memory name, string memory symbol, address token0, address token1) external payable;
}

interface ICallee {
    function callback(bytes calldata) external payable;
}

// Just from UniswapV2
library UQ112x112 {
    uint224 private constant K = 1 << 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        unchecked {
            z = uint224(y) * K; // never overflows
        }
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

contract Pool is IPool, ERC20 {
    using FixedPointMathLib for uint256;
    using UQ112x112 for uint224;
    using SafeERC20 for IERC20;

    IERC20 public token0;
    IERC20 public token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint224 public cumulativePrice0;
    uint224 public cumulativePrice1;

    uint32 public priceUpdatedAt;

    string private lpTokenName;
    string private lpTokenSym;

    event Swap(address to, uint256 token0In, uint256 token1In, uint256 token0Out, uint256 token1Out);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Mint(address to, uint256 amount);
    event Burn(address to, uint256 amount);

    error InvalidAmount();
    error InvalidK();
    error Slippage();
    error Reentrancy();
    
    function initialize(string memory _name, string memory _symbol, address _token0, address _token1)
        external
        payable
    {
        lpTokenName = _name;
        lpTokenSym = _symbol;
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function name() public view override returns (string memory) {
        return lpTokenName;
    }

    function symbol() public view override returns (string memory) {
        return lpTokenSym;
    }

    function swap(uint256 token0Amount, uint256 token1Amount, uint256 minToGet) external nonreentrant {
        if (token0Amount > 0 && token1Amount > 0) {
            revert InvalidAmount();
        }

        uint256 _token0Amount = token0Amount > 0 ? token0Amount * 997 : 0;
        uint256 _token1Amount = token1Amount > 0 ? token1Amount * 997 : 0;

        uint256 toSendToken0 = reserve0 * _token1Amount / (reserve1 * 1e3 + _token1Amount);
        uint256 toSendToken1 = reserve1 * _token0Amount / (reserve0 * 1e3 + _token0Amount);

        if (token0Amount > 0 && toSendToken0 < minToGet) {
            revert Slippage();
        }
        if (token1Amount > 0 && toSendToken1 < minToGet) {
            revert Slippage();
        }

        uint256 _reserve0 = reserve0 + token0Amount - toSendToken0;
        uint256 _reserve1 = reserve1 + token1Amount - toSendToken1;

        if (_reserve0 * _reserve1 < reserve0 * reserve1) {
            revert InvalidK();
        }

        token0.safeTransferFrom(msg.sender, address(this), token0Amount);
        token1.safeTransferFrom(msg.sender, address(this), token1Amount);

        token0.safeTransfer(msg.sender, toSendToken0);
        token1.safeTransfer(msg.sender, toSendToken1);

        // forgefmt: disable-next-item
        _updatePrices(
            _reserve0,
            _reserve1
        );

        // forgefmt: disable-next-item
        emit Swap(
            msg.sender,
            token0Amount,
            token1Amount,
            toSendToken0,
            toSendToken1
        );
    }

    function deposit(uint256 token0Amount, uint256 token1Amount) external nonreentrant returns (uint256 liquidity) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply > 0) {
            liquidity = (token0Amount * _totalSupply / reserve0).min(token1Amount * _totalSupply / reserve1);
        } else {
            liquidity = (token0Amount * token1Amount).sqrt();
        }
        if (liquidity == 0) revert InvalidAmount();

        token0Amount = _totalSupply > 0 ? liquidity * reserve0 / _totalSupply : token0Amount;
        token1Amount = _totalSupply > 0 ? liquidity * reserve1 / _totalSupply : token1Amount;

        token0.safeTransferFrom(msg.sender, address(this), token0Amount);
        token1.safeTransferFrom(msg.sender, address(this), token1Amount);

        _mint(msg.sender, liquidity);

        // forgefmt: disable-next-item
        _updatePrices(
            reserve0 + token0Amount,
            reserve1 + token1Amount
        );

        emit Mint(msg.sender, liquidity);
    }

    function withdraw(uint256 liquidity, uint256 amount0Min, uint256 amount1Min) external virtual nonreentrant {
        liquidity = liquidity > 0 ? liquidity : balanceOf(msg.sender);
        uint256 _totalSupply = totalSupply();

        uint256 token0Amount = reserve0 * liquidity / _totalSupply;
        uint256 token1Amount = reserve1 * liquidity / _totalSupply;

        if (token0Amount < amount0Min) {
            revert Slippage();
        }
        if (token1Amount < amount1Min) {
            revert Slippage();
        }

        token0.safeTransfer(msg.sender, token0Amount);
        token1.safeTransfer(msg.sender, token1Amount);

        _burn(msg.sender, liquidity);

        unchecked {
            // forgefmt: disable-next-item
            _updatePrices(
                reserve0 - token0Amount,
                reserve1 - token1Amount
            );
        }

        emit Burn(msg.sender, liquidity);
    }


    function flashLoan(uint256 token0Loan, uint256 token1Loan, bytes calldata data) nonreentrant external {
        if (token0Loan > reserve0 || token1Loan > reserve1) {
            revert InvalidAmount();
        }

        token0.safeTransfer(msg.sender, token0Loan);
        token1.safeTransfer(msg.sender, token1Loan);

        ICallee(msg.sender).callback(data);

        uint256 _token0Amount = token0Loan * 1003 / 1e3;
        uint256 _token1Amount = token1Loan * 1003 / 1e3;

        token0.safeTransferFrom(msg.sender, address(this), _token0Amount);
        token1.safeTransferFrom(msg.sender, address(this), _token1Amount);

        // forgefmt: disable-next-item
        _updatePrices(
            reserve0 - token0Loan + _token0Amount,
            reserve1 - token1Loan + _token1Amount
        );
    }

    function lock() external view returns (bool _lock) {
        assembly ("memory-safe") {
            _lock := tload(0x10C3)
        }
    }

    function _updatePrices(uint256 _reserve0, uint256 _reserve1) internal {
        uint32 timeDelta = uint32(block.timestamp) - priceUpdatedAt;

        {
            // Save on reading the storage values.
            uint112 reserve0_ = uint112(reserve0);
            uint112 reserve1_ = uint112(reserve1);

            // Update once per block.
            if (timeDelta > 0 && reserve0_ > 0 && reserve1_ > 0) {
                cumulativePrice0 += UQ112x112.encode(reserve1_).uqdiv(reserve0_) * timeDelta;
                cumulativePrice1 += UQ112x112.encode(reserve0_).uqdiv(reserve1_) * timeDelta;
            }
        }

        priceUpdatedAt = uint32(block.timestamp);

        reserve0 = _reserve0;
        reserve1 = _reserve1;

        emit Sync(_reserve0, _reserve1);
    }

    modifier nonreentrant() {
        assembly ("memory-safe") {
               let lock := tload(0x10C3)
               if iszero(iszero(lock)) {
                   // revert Reentrancy()
                   mstore(0x00, 0xab143c06)
                   revert(0x1c, 0x04)
               }
               tstore(0x10C3, 1)
        }

        _;

        assembly ("memory-safe") {
            tstore(0x10C3, 0)
        }
    }
}
