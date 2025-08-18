;; Farm Loyalty Tokens Smart Contract

(define-fungible-token loyalty-token)

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-FARM-NOT-FOUND (err u103))
(define-constant ERR-PRODUCE-NOT-FOUND (err u104))
(define-constant ERR-INSUFFICIENT-TOKENS (err u105))
(define-constant ERR-INVALID-REDEMPTION (err u106))
(define-constant ERR-FARM-ALREADY-EXISTS (err u107))
(define-constant ERR-VISIT-NOT-AVAILABLE (err u108))
(define-constant ERR-ALREADY-REDEEMED (err u109))

(define-data-var next-farm-id uint u1)
(define-data-var next-produce-id uint u1)
(define-data-var next-recipe-id uint u1)
(define-data-var next-visit-id uint u1)
(define-data-var contract-balance uint u0)

(define-map farms 
  { farm-id: uint } 
  { 
    name: (string-ascii 50), 
    owner: principal, 
    location: (string-ascii 100),
    active: bool,
    total-sales: uint,
    created-at: uint
  })

(define-map produce-items 
  { produce-id: uint } 
  { 
    farm-id: uint, 
    name: (string-ascii 50), 
    price: uint, 
    tokens-reward: uint,
    available: bool,
    total-sold: uint
  })

(define-map user-purchases 
  { user: principal, purchase-id: uint } 
  { 
    farm-id: uint, 
    produce-id: uint, 
    amount-paid: uint, 
    tokens-earned: uint, 
    timestamp: uint 
  })

(define-map user-tokens 
  { user: principal } 
  { balance: uint, total-earned: uint, total-spent: uint })

(define-map discount-redemptions 
  { user: principal, redemption-id: uint } 
  { 
    discount-percent: uint, 
    tokens-spent: uint, 
    farm-id: uint,
    used: bool,
    expires-at: uint,
    created-at: uint
  })

(define-map recipe-library 
  { recipe-id: uint } 
  { 
    name: (string-ascii 50), 
    ingredients: (string-ascii 200), 
    instructions: (string-ascii 500),
    token-cost: uint,
    farm-id: uint,
    active: bool
  })

(define-map farm-visits 
  { visit-id: uint } 
  { 
    farm-id: uint, 
    visitor: principal, 
    visit-date: uint, 
    tokens-spent: uint,
    status: (string-ascii 20),
    created-at: uint
  })

(define-map user-purchase-counter { user: principal } { count: uint })
(define-map user-redemption-counter { user: principal } { count: uint })

(define-public (register-farm (name (string-ascii 50)) (location (string-ascii 100)))
  (let ((farm-id (var-get next-farm-id)))
    (asserts! (is-none (map-get? farms { farm-id: farm-id })) ERR-FARM-ALREADY-EXISTS)
    (map-set farms 
      { farm-id: farm-id }
      { 
        name: name, 
        owner: tx-sender, 
        location: location,
        active: true,
        total-sales: u0,
        created-at: stacks-block-height
      })
    (var-set next-farm-id (+ farm-id u1))
    (ok farm-id)))

(define-public (add-produce (farm-id uint) (name (string-ascii 50)) (price uint) (tokens-reward uint))
  (let ((farm-data (unwrap! (map-get? farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
        (produce-id (var-get next-produce-id)))
    (asserts! (is-eq (get owner farm-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> price u0) ERR-INVALID-AMOUNT)
    (map-set produce-items 
      { produce-id: produce-id }
      { 
        farm-id: farm-id, 
        name: name, 
        price: price, 
        tokens-reward: tokens-reward,
        available: true,
        total-sold: u0
      })
    (var-set next-produce-id (+ produce-id u1))
    (ok produce-id)))

(define-public (purchase-produce (produce-id uint) (payment uint))
  (let ((produce-data (unwrap! (map-get? produce-items { produce-id: produce-id }) ERR-PRODUCE-NOT-FOUND))
        (farm-data (unwrap! (map-get? farms { farm-id: (get farm-id produce-data) }) ERR-FARM-NOT-FOUND))
        (user-counter-data (default-to { count: u0 } (map-get? user-purchase-counter { user: tx-sender })))
        (purchase-id (get count user-counter-data))
        (tokens-to-award (get tokens-reward produce-data)))
    (asserts! (get available produce-data) ERR-PRODUCE-NOT-FOUND)
    (asserts! (>= payment (get price produce-data)) ERR-INSUFFICIENT-BALANCE)
    (try! (stx-transfer? payment tx-sender (get owner farm-data)))
    (try! (ft-mint? loyalty-token tokens-to-award tx-sender))
    (map-set user-purchases 
      { user: tx-sender, purchase-id: purchase-id }
      { 
        farm-id: (get farm-id produce-data), 
        produce-id: produce-id, 
        amount-paid: payment, 
        tokens-earned: tokens-to-award, 
        timestamp: stacks-block-height 
      })
    (map-set user-purchase-counter { user: tx-sender } { count: (+ purchase-id u1) })
    (let ((current-tokens (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender }))))
      (map-set user-tokens 
        { user: tx-sender }
        { 
          balance: (+ (get balance current-tokens) tokens-to-award),
          total-earned: (+ (get total-earned current-tokens) tokens-to-award),
          total-spent: (get total-spent current-tokens)
        }))
    (map-set produce-items 
      { produce-id: produce-id }
      (merge produce-data { total-sold: (+ (get total-sold produce-data) u1) }))
    (map-set farms 
      { farm-id: (get farm-id produce-data) }
      (merge farm-data { total-sales: (+ (get total-sales farm-data) payment) }))
    (ok tokens-to-award)))

(define-public (redeem-discount (farm-id uint) (discount-percent uint) (tokens-to-spend uint))
  (let ((farm-data (unwrap! (map-get? farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
        (user-tokens-data (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender })))
        (user-redemption-data (default-to { count: u0 } (map-get? user-redemption-counter { user: tx-sender })))
        (redemption-id (get count user-redemption-data))
        (required-tokens (* discount-percent u10)))
    (asserts! (and (> discount-percent u0) (<= discount-percent u50)) ERR-INVALID-REDEMPTION)
    (asserts! (>= tokens-to-spend required-tokens) ERR-INSUFFICIENT-TOKENS)
    (asserts! (>= (get balance user-tokens-data) tokens-to-spend) ERR-INSUFFICIENT-TOKENS)
    (try! (ft-burn? loyalty-token tokens-to-spend tx-sender))
    (map-set discount-redemptions 
      { user: tx-sender, redemption-id: redemption-id }
      { 
        discount-percent: discount-percent, 
        tokens-spent: tokens-to-spend, 
        farm-id: farm-id,
        used: false,
        expires-at: (+ stacks-block-height u1000),
        created-at: stacks-block-height
      })
    (map-set user-redemption-counter { user: tx-sender } { count: (+ redemption-id u1) })
    (map-set user-tokens 
      { user: tx-sender }
      { 
        balance: (- (get balance user-tokens-data) tokens-to-spend),
        total-earned: (get total-earned user-tokens-data),
        total-spent: (+ (get total-spent user-tokens-data) tokens-to-spend)
      })
    (ok redemption-id)))

(define-public (add-recipe (farm-id uint) (name (string-ascii 50)) (ingredients (string-ascii 200)) (instructions (string-ascii 500)) (token-cost uint))
  (let ((farm-data (unwrap! (map-get? farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
        (recipe-id (var-get next-recipe-id)))
    (asserts! (is-eq (get owner farm-data) tx-sender) ERR-NOT-AUTHORIZED)
    (map-set recipe-library 
      { recipe-id: recipe-id }
      { 
        name: name, 
        ingredients: ingredients, 
        instructions: instructions,
        token-cost: token-cost,
        farm-id: farm-id,
        active: true
      })
    (var-set next-recipe-id (+ recipe-id u1))
    (ok recipe-id)))

(define-public (unlock-recipe (recipe-id uint))
  (let ((recipe-data (unwrap! (map-get? recipe-library { recipe-id: recipe-id }) ERR-INVALID-REDEMPTION))
        (user-tokens-data (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender })))
        (token-cost (get token-cost recipe-data)))
    (asserts! (get active recipe-data) ERR-INVALID-REDEMPTION)
    (asserts! (>= (get balance user-tokens-data) token-cost) ERR-INSUFFICIENT-TOKENS)
    (try! (ft-burn? loyalty-token token-cost tx-sender))
    (map-set user-tokens 
      { user: tx-sender }
      { 
        balance: (- (get balance user-tokens-data) token-cost),
        total-earned: (get total-earned user-tokens-data),
        total-spent: (+ (get total-spent user-tokens-data) token-cost)
      })
    (ok recipe-data)))

(define-public (book-farm-visit (farm-id uint) (visit-date uint) (tokens-to-spend uint))
  (let ((farm-data (unwrap! (map-get? farms { farm-id: farm-id }) ERR-FARM-NOT-FOUND))
        (user-tokens-data (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender })))
        (visit-id (var-get next-visit-id))
        (required-tokens u100))
    (asserts! (get active farm-data) ERR-FARM-NOT-FOUND)
    (asserts! (>= tokens-to-spend required-tokens) ERR-INSUFFICIENT-TOKENS)
    (asserts! (>= (get balance user-tokens-data) tokens-to-spend) ERR-INSUFFICIENT-TOKENS)
    (asserts! (> visit-date stacks-block-height) ERR-INVALID-AMOUNT)
    (try! (ft-burn? loyalty-token tokens-to-spend tx-sender))
    (map-set farm-visits 
      { visit-id: visit-id }
      { 
        farm-id: farm-id, 
        visitor: tx-sender, 
        visit-date: visit-date, 
        tokens-spent: tokens-to-spend,
        status: "pending",
        created-at: stacks-block-height
      })
    (var-set next-visit-id (+ visit-id u1))
    (map-set user-tokens 
      { user: tx-sender }
      { 
        balance: (- (get balance user-tokens-data) tokens-to-spend),
        total-earned: (get total-earned user-tokens-data),
        total-spent: (+ (get total-spent user-tokens-data) tokens-to-spend)
      })
    (ok visit-id)))

(define-public (confirm-visit (visit-id uint))
  (let ((visit-data (unwrap! (map-get? farm-visits { visit-id: visit-id }) ERR-VISIT-NOT-AVAILABLE))
        (farm-data (unwrap! (map-get? farms { farm-id: (get farm-id visit-data) }) ERR-FARM-NOT-FOUND)))
    (asserts! (is-eq (get owner farm-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status visit-data) "pending") ERR-ALREADY-REDEEMED)
    (map-set farm-visits 
      { visit-id: visit-id }
      (merge visit-data { status: "confirmed" }))
    (ok true)))

(define-public (use-discount (user principal) (redemption-id uint))
  (let ((discount-data (unwrap! (map-get? discount-redemptions { user: user, redemption-id: redemption-id }) ERR-INVALID-REDEMPTION)))
    (asserts! (not (get used discount-data)) ERR-ALREADY-REDEEMED)
    (asserts! (< stacks-block-height (get expires-at discount-data)) ERR-INVALID-REDEMPTION)
    (map-set discount-redemptions 
      { user: user, redemption-id: redemption-id }
      (merge discount-data { used: true }))
    (ok (get discount-percent discount-data))))

(define-read-only (get-farm-info (farm-id uint))
  (map-get? farms { farm-id: farm-id }))

(define-read-only (get-produce-info (produce-id uint))
  (map-get? produce-items { produce-id: produce-id }))

(define-read-only (get-user-tokens (user principal))
  (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: user })))

(define-read-only (get-user-purchase (user principal) (purchase-id uint))
  (map-get? user-purchases { user: user, purchase-id: purchase-id }))

(define-read-only (get-discount-redemption (user principal) (redemption-id uint))
  (map-get? discount-redemptions { user: user, redemption-id: redemption-id }))

(define-read-only (get-recipe (recipe-id uint))
  (map-get? recipe-library { recipe-id: recipe-id }))

(define-read-only (get-farm-visit (visit-id uint))
  (map-get? farm-visits { visit-id: visit-id }))

(define-read-only (get-token-balance (user principal))
  (ft-get-balance loyalty-token user))

(define-read-only (get-next-farm-id)
  (var-get next-farm-id))

(define-read-only (get-next-produce-id)
  (var-get next-produce-id))

(define-read-only (get-next-recipe-id)
  (var-get next-recipe-id))

(define-read-only (get-next-visit-id)
  (var-get next-visit-id))
