🎮 GamingAssetHub
=================

Introduction
------------

**GamingAssetHub** is a smart contract for a decentralized marketplace on the Stacks blockchain, designed to facilitate the secure and trustless trading of NFT-based gaming assets. It provides a robust framework for asset listings, direct sales, and a comprehensive auction system. The contract ensures secure ownership transfer and configurable marketplace fees, promoting a fair and transparent ecosystem for gamers and collectors.

* * * * *

Features
--------

-   **Secure Asset Listings**: Owners can list their gaming assets for a fixed price, with full control over the listing status.

-   **Direct Sales**: A secure mechanism for purchasing listed assets, handling payment transfer and ownership verification in a single transaction.

-   **Configurable Marketplace Fee**: The contract owner can adjust the marketplace fee, allowing for dynamic fee management. Fees are automatically deducted from sales and transferred to the contract owner.

-   **Comprehensive Auction System**:

    -   **Advanced Auctions**: Create auctions with a starting price, a defined duration, a reserve price, and an optional buyout price.

    -   **Bid Management**: The contract manages the highest bid and bidder, preventing bids below the current highest bid.

    -   **Automated Settlement**: The auction automatically settles upon completion, transferring the asset to the highest bidder and distributing the funds to the seller and marketplace.

-   **Ownership Verification**: All critical functions, such as updating a listing or creating an auction, include checks to ensure that only the asset's rightful owner can perform the action.

* * * * *

Constants and Error Codes
-------------------------

The contract defines a set of constants and error codes to provide clear and descriptive feedback on transaction outcomes.

| Error Code | Constant | Description |
| --- | --- | --- |
| `u100` | `ERR-OWNER-ONLY` | The function can only be called by the contract owner. |
| `u101` | `ERR-NOT-AUTHORIZED` | The caller is not authorized to perform this action. |
| `u102` | `ERR-ASSET-NOT-FOUND` | The specified asset ID does not exist. |
| `u103` | `ERR-INVALID-PRICE` | The price or fee is invalid (e.g., zero or too high). |
| `u104` | `ERR-INSUFFICIENT-FUNDS` | The caller has insufficient funds to complete the purchase. |
| `u105` | `ERR-ASSET-NOT-FOR-SALE` | The asset is not currently listed for direct sale. |
| `u106` | `ERR-ALREADY-LISTED` | The asset is already listed for sale or auction. |
| `u107` | `ERR-AUCTION-ACTIVE` | The asset is currently in an active auction. |
| `u108` | `ERR-AUCTION-ENDED` | The auction has already ended. |
| `u109` | `ERR-BID-TOO-LOW` | The new bid is not higher than the current highest bid. |

* * * * *

Data Structures
---------------

The contract uses two main maps and two data variables to store information about the assets, auctions, and marketplace configuration.

-   `asset-listings`: A map that stores the details of each gaming asset.

    -   `asset-id`: The unique identifier for the asset.

    -   `owner`: The principal (address) of the current owner.

    -   `price`: The fixed price for direct sale.

    -   `for-sale`: A boolean indicating if the asset is available for direct purchase.

    -   `game-title`: The name of the game the asset belongs to.

    -   `asset-type`: The category or type of the asset (e.g., "Weapon", "Skin").

-   `auctions`: A map that stores information about ongoing auctions.

    -   `asset-id`: The unique identifier for the auctioned asset.

    -   `seller`: The principal of the seller.

    -   `starting-price`: The initial price of the auction.

    -   `current-bid`: The current highest bid.

    -   `highest-bidder`: The principal of the highest bidder.

    -   `end-block`: The block height at which the auction ends.

    -   `active`: A boolean indicating if the auction is still active.

-   `marketplace-fee-percent`: A data variable storing the marketplace fee in basis points (e.g., `u250` for 2.5%).

-   `total-assets-listed`: A data variable tracking the total number of assets that have been listed on the marketplace.

* * * * *

Private Functions
-----------------

These functions are internal helpers used by the public functions to perform specific tasks. They cannot be called directly by an external user.

-   `calculate-fee (amount uint)`: Computes the marketplace fee based on a given amount and the `marketplace-fee-percent`.

-   `transfer-asset-ownership (asset-id uint) (from principal) (to principal)`: Updates the ownership of an asset in the `asset-listings` map.

-   `validate-asset-owner (asset-id uint) (caller principal)`: Checks if the caller of a function is the legitimate owner of the specified asset.

-   `finalize-auction-sale (asset-id uint) (buyer principal) (final-price uint)`: Handles the final steps of an auction, including transferring the asset to the buyer, distributing funds to the seller, and deleting the auction entry.

* * * * *

Public Functions
----------------

### `list-asset`

-   **Signature**: `(list-asset (asset-id uint) (price uint) (game-title (string-ascii 50)) (asset-type (string-ascii 20)))`

-   **Description**: Creates a new listing for a gaming asset, allowing it to be sold for a fixed price.

-   **Parameters**:

    -   `asset-id`: The unique ID of the asset.

    -   `price`: The fixed price for the asset.

    -   `game-title`: The name of the game.

    -   `asset-type`: The type of asset.

-   **Returns**: `(ok uint)` on success, or an error code on failure.

### `update-listing-price`

-   **Signature**: `(update-listing-price (asset-id uint) (new-price uint))`

-   **Description**: Allows the asset owner to change the fixed price of a listed asset.

-   **Returns**: `(ok bool)` on success, or an error code on failure.

### `delist-asset`

-   **Signature**: `(delist-asset (asset-id uint))`

-   **Description**: Removes an asset from the direct sales marketplace. The asset remains owned by the caller but is no longer for sale.

-   **Returns**: `(ok bool)` on success, or an error code on failure.

### `purchase-asset`

-   **Signature**: `(purchase-asset (asset-id uint))`

-   **Description**: Facilitates the purchase of a listed asset. Transfers the asset to the buyer and distributes the payment to the seller and contract owner.

-   **Returns**: `(ok bool)` on success, or an error code on failure.

### `set-marketplace-fee`

-   **Signature**: `(set-marketplace-fee (new-fee-percent uint))`

-   **Description**: **Contract owner-only function**. Sets the new marketplace fee in basis points.

-   **Returns**: `(ok bool)` on success, or an error code on failure.

### `create-auction-with-advanced-features`

-   **Signature**: `(create-auction-with-advanced-features (asset-id uint) (starting-price uint) (duration-blocks uint) (reserve-price uint) (buyout-price (optional uint)))`

-   **Description**: Initiates a new auction for a gaming asset. Removes the asset from direct sale and sets up the auction parameters.

-   **Returns**: `(ok { auction-created: bool, immediate-sale: bool })` on success, or an error code on failure.

* * * * *

Read-Only Functions
-------------------

-   `get-asset-listing (asset-id uint)`: Retrieves the details of a specific asset listing.

-   `get-auction-info (asset-id uint)`: Retrieves the details of an active auction.

-   `get-marketplace-fee`: Returns the current marketplace fee percentage in basis points.

-   `get-total-listed-assets`: Returns the total number of assets that have been listed on the marketplace.

* * * * *

License
-------

This project is licensed under the MIT License. See the `LICENSE` file for details.

* * * * *

Contribution
------------

Contributions are welcome! Please feel free to open an issue or submit a pull request on our GitHub repository. We appreciate your feedback and help in making this project better.

![profile picture](https://lh3.googleusercontent.com/a/ACg8ocJ_vsw7TaCCeMuQ9lczLCzqs47IOD2H_aUfBxy6CgG3iFhEGtMA=s64-c)
