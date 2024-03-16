### ERC721A

How the ERC saves gas?

1. It doesn't store additional data as ERC721Enumerable does.
2. In batch minting balance of a user is being updated only once per whole batch for the user.
3. Token ownership is optimized for write operations by writing one value per batch.

Where the ERC adds costs?

Read operations are more expensive. To get the owner of a token it requires to lookup through the holders list in some
cases. There's no enumeration of tokens by owner, so other techniques should be used to achieve this.
