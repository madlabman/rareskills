### SafeERC20

This is a wrapper around ERC20 methods that allows for more consistent and safer as it stands from the name way to
communicate with ERC20 tokens.

There are a few reasons for this wrapper to be used, described below.

#### Inconsistent ERC20 transfers implementations

While the ERC20 specifications say that the `transfer` and `transferFrom` functions should throw an exception in the
case of failure, some implementations are using the boolean return value to indicate an error. It means a contract
accepting an arbitrary ERC20 token should check both cases, and **SafeERC20** solves it in favor of a developer
introducing `safeTransfer` and `safeTransferFrom` functions that always throw.

#### Inconsistent ERC20 approvals implementations

ERC20 `approve` implementations have the same shortcomings as the `transfer`. At the same time, some implementations
require a user to reset allowance to zero before changing it to a new value (such as USDT). This is done to reduce the
impact of an approval front-running attack from an ERC20 token implementation side. To solve both issues, there are
`safeIncreaseAllowance` and its counterpart `safeDecreaseAllowance` in the **SafeERC20** which do all the checks and
provide a simple interface.

#### ERC1363 wrappers

ERC1363 is a standard for a token to notify the receiver about the transfer. But the tokens `transferAndCall`,
`transferFromAndCall`, `approveAndCall` revert if the target of the calls doesn't support the required interfaces.
Instead, the wrappers from the **SafeERC20** can be used to get the unified interface.
