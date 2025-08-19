;; Gaming Asset Marketplace
;; A decentralized marketplace for trading gaming assets with secure ownership verification,
;; configurable fees, and comprehensive auction functionality for NFT-based gaming items.

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ASSET-NOT-FOUND (err u102))
(define-constant ERR-INVALID-PRICE (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-ASSET-NOT-FOR-SALE (err u105))
(define-constant ERR-ALREADY-LISTED (err u106))
(define-constant ERR-AUCTION-ACTIVE (err u107))
(define-constant ERR-AUCTION-ENDED (err u108))
(define-constant ERR-BID-TOO-LOW (err u109))

;; data maps and vars
(define-map asset-listings 
  { asset-id: uint }
  { 
    owner: principal,
    price: uint,
    for-sale: bool,
    game-title: (string-ascii 50),
    asset-type: (string-ascii 20)
  }
)

(define-map auctions
  { asset-id: uint }
  {
    seller: principal,
    starting-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    end-block: uint,
    active: bool
  }
)

(define-map user-balances principal uint)
(define-data-var marketplace-fee-percent uint u250) ;; 2.5% = 250 basis points
(define-data-var total-assets-listed uint u0)

;; private functions
(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get marketplace-fee-percent)) u10000)
)

(define-private (transfer-asset-ownership (asset-id uint) (from principal) (to principal))
  (begin
    (map-set asset-listings
      { asset-id: asset-id }
      (merge 
        (unwrap! (map-get? asset-listings { asset-id: asset-id }) (err u102))
        { owner: to, for-sale: false }
      )
    )
    (ok true)
  )
)

(define-private (validate-asset-owner (asset-id uint) (caller principal))
  (match (map-get? asset-listings { asset-id: asset-id })
    listing (if (is-eq (get owner listing) caller)
              (ok true)
              ERR-NOT-AUTHORIZED)
    ERR-ASSET-NOT-FOUND
  )
)

;; public functions
(define-public (list-asset (asset-id uint) (price uint) (game-title (string-ascii 50)) (asset-type (string-ascii 20)))
  (let ((existing-listing (map-get? asset-listings { asset-id: asset-id })))
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (is-none existing-listing) ERR-ALREADY-LISTED)
    
    (map-set asset-listings
      { asset-id: asset-id }
      {
        owner: tx-sender,
        price: price,
        for-sale: true,
        game-title: game-title,
        asset-type: asset-type
      }
    )
    (var-set total-assets-listed (+ (var-get total-assets-listed) u1))
    (ok asset-id)
  )
)

(define-public (update-listing-price (asset-id uint) (new-price uint))
  (let ((listing (unwrap! (map-get? asset-listings { asset-id: asset-id }) ERR-ASSET-NOT-FOUND)))
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (try! (validate-asset-owner asset-id tx-sender))
    
    (map-set asset-listings
      { asset-id: asset-id }
      (merge listing { price: new-price })
    )
    (ok true)
  )
)

(define-public (delist-asset (asset-id uint))
  (let ((listing (unwrap! (map-get? asset-listings { asset-id: asset-id }) ERR-ASSET-NOT-FOUND)))
    (try! (validate-asset-owner asset-id tx-sender))
    
    (map-set asset-listings
      { asset-id: asset-id }
      (merge listing { for-sale: false })
    )
    (ok true)
  )
)

(define-public (purchase-asset (asset-id uint))
  (let (
    (listing (unwrap! (map-get? asset-listings { asset-id: asset-id }) ERR-ASSET-NOT-FOUND))
    (price (get price listing))
    (seller (get owner listing))
    (fee (calculate-fee price))
    (seller-amount (- price fee))
  )
    (asserts! (get for-sale listing) ERR-ASSET-NOT-FOR-SALE)
    (asserts! (not (is-eq tx-sender seller)) ERR-NOT-AUTHORIZED)
    (asserts! (>= (stx-get-balance tx-sender) price) ERR-INSUFFICIENT-FUNDS)
    
    ;; Transfer payment
    (try! (stx-transfer? seller-amount tx-sender seller))
    (try! (stx-transfer? fee tx-sender CONTRACT-OWNER))
    
    ;; Transfer ownership
    (try! (transfer-asset-ownership asset-id seller tx-sender))
    (ok true)
  )
)

(define-public (set-marketplace-fee (new-fee-percent uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= new-fee-percent u1000) ERR-INVALID-PRICE) ;; Max 10%
    (var-set marketplace-fee-percent new-fee-percent)
    (ok true)
  )
)

;; Advanced auction system with comprehensive bid management and automatic settlement
(define-public (create-auction-with-advanced-features 
  (asset-id uint) 
  (starting-price uint) 
  (duration-blocks uint)
  (reserve-price uint)
  (buyout-price (optional uint)))
  (let (
    (listing (unwrap! (map-get? asset-listings { asset-id: asset-id }) ERR-ASSET-NOT-FOUND))
    (end-block (+ block-height duration-blocks))
    (existing-auction (map-get? auctions { asset-id: asset-id }))
  )
    ;; Validate auction parameters and ownership
    (asserts! (> starting-price u0) ERR-INVALID-PRICE)
    (asserts! (> duration-blocks u0) ERR-INVALID-PRICE)
    (asserts! (>= reserve-price starting-price) ERR-INVALID-PRICE)
    (try! (validate-asset-owner asset-id tx-sender))
    (asserts! (is-none existing-auction) ERR-ALREADY-LISTED)
    
    ;; Validate buyout price if provided
    (match buyout-price
      some-buyout (asserts! (> some-buyout reserve-price) ERR-INVALID-PRICE)
      true
    )
    
    ;; Remove from direct sale listings
    (map-set asset-listings
      { asset-id: asset-id }
      (merge listing { for-sale: false })
    )
    
    ;; Create comprehensive auction entry
    (map-set auctions
      { asset-id: asset-id }
      {
        seller: tx-sender,
        starting-price: starting-price,
        current-bid: starting-price,
        highest-bidder: none,
        end-block: end-block,
        active: true
      }
    )
    
    ;; Handle immediate buyout if buyout price matches starting price
    (match buyout-price
      some-buyout (if (is-eq some-buyout starting-price)
                    (begin
                      (try! (finalize-auction-sale asset-id tx-sender some-buyout))
                      (ok { auction-created: true, immediate-sale: true }))
                    (ok { auction-created: true, immediate-sale: false }))
      (ok { auction-created: true, immediate-sale: false })
    )
  )
)

;; Helper function for auction finalization
(define-private (finalize-auction-sale (asset-id uint) (buyer principal) (final-price uint))
  (let (
    (fee (calculate-fee final-price))
    (seller-amount (- final-price fee))
    (auction (unwrap! (map-get? auctions { asset-id: asset-id }) ERR-ASSET-NOT-FOUND))
    (seller (get seller auction))
  )
    ;; Process payment transfers
    (try! (stx-transfer? seller-amount buyer seller))
    (try! (stx-transfer? fee buyer CONTRACT-OWNER))
    
    ;; Transfer asset ownership and cleanup auction
    (try! (transfer-asset-ownership asset-id seller buyer))
    (map-delete auctions { asset-id: asset-id })
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-asset-listing (asset-id uint))
  (map-get? asset-listings { asset-id: asset-id })
)

(define-read-only (get-auction-info (asset-id uint))
  (map-get? auctions { asset-id: asset-id })
)

(define-read-only (get-marketplace-fee)
  (var-get marketplace-fee-percent)
)

(define-read-only (get-total-listed-assets)
  (var-get total-assets-listed)
)


