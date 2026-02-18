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
(define-constant ERR-CHALLENGE-NOT-FOUND (err u110))
(define-constant ERR-CHALLENGE-INACTIVE (err u111))
(define-constant ERR-CHALLENGE-EXPIRED (err u112))
(define-constant ERR-ALREADY-PARTICIPATING (err u113))
(define-constant ERR-EVENT-NOT-ACTIVE (err u114))
(define-constant ERR-ACHIEVEMENT-NOT-UNLOCKED (err u115))
(define-constant ERR-STAKE-NOT-FOUND (err u116))
(define-constant ERR-STAKE-LOCKED (err u117))
(define-constant ERR-INVALID-STAKE-TIER (err u118))
(define-constant ERR-INSUFFICIENT-STAKE-BALANCE (err u119))
(define-constant ERR-STAKE-ALREADY-WITHDRAWN (err u120))
(define-constant ERR-CANNOT-GIFT-SELF (err u121))
(define-constant ERR-GIFT-NOT-FOUND (err u122))
(define-constant MAX-GIFT-MESSAGE-LEN u100)

(define-constant CHALLENGE-DURATION u1440)
(define-constant SEASONAL-EVENT-DURATION u10080)
(define-constant MIN-PARTICIPANTS u3)
(define-constant MAX-CHALLENGE-REWARD u1000)
(define-constant COMMUNITY-BONUS-MULTIPLIER u150)
(define-constant STAKE-TIER-BASIC u1)
(define-constant STAKE-TIER-SILVER u2)
(define-constant STAKE-TIER-GOLD u3)
(define-constant STAKE-APR-BASIC u500)
(define-constant STAKE-APR-SILVER u1000)
(define-constant STAKE-APR-GOLD u1500)
(define-constant STAKE-DURATION-BASIC u1440)
(define-constant STAKE-DURATION-SILVER u4320)
(define-constant STAKE-DURATION-GOLD u8640)
(define-constant EARLY-WITHDRAWAL-PENALTY u2000)

(define-data-var next-farm-id uint u1)
(define-data-var next-produce-id uint u1)
(define-data-var next-recipe-id uint u1)
(define-data-var next-visit-id uint u1)
(define-data-var contract-balance uint u0)
(define-data-var next-challenge-id uint u1)
(define-data-var next-event-id uint u1)
(define-data-var active-seasonal-event uint u0)
(define-data-var total-community-points uint u0)
(define-data-var next-stake-id uint u1)
(define-data-var total-staked-tokens uint u0)
(define-data-var next-gift-id uint u1)
(define-data-var total-gifts-sent uint u0)

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

(define-map community-challenges
  { challenge-id: uint }
  {
    name: (string-ascii 60),
    description: (string-ascii 200),
    challenge-type: (string-ascii 20),
    target-value: uint,
    reward-tokens: uint,
    farm-id: (optional uint),
    start-block: uint,
    end-block: uint,
    participants: uint,
    completed: uint,
    active: bool
  }
)

(define-map seasonal-events
  { event-id: uint }
  {
    name: (string-ascii 60),
    theme: (string-ascii 40),
    description: (string-ascii 250),
    bonus-multiplier: uint,
    start-block: uint,
    end-block: uint,
    total-participants: uint,
    community-goal: uint,
    current-progress: uint,
    active: bool
  }
)

(define-map user-challenge-participation
  { user: principal, challenge-id: uint }
  {
    joined-at: uint,
    current-progress: uint,
    completed: bool,
    reward-claimed: bool,
    contribution-score: uint
  }
)

(define-map community-achievements
  { achievement-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 150),
    unlock-condition: (string-ascii 100),
    reward-tokens: uint,
    participants-required: uint,
    current-participants: uint,
    unlocked: bool,
    created-at: uint
  }
)

(define-map user-achievements
  { user: principal, achievement-id: uint }
  {
    unlocked-at: uint,
    reward-claimed: bool
  }
)

(define-map token-stakes
  { stake-id: uint }
  {
    staker: principal,
    amount: uint,
    tier: uint,
    start-block: uint,
    unlock-block: uint,
    apr-rate: uint,
    withdrawn: bool,
    rewards-claimed: uint
  }
)

(define-map user-stake-info
  { user: principal }
  {
    total-staked: uint,
    active-stakes: uint,
    total-rewards-earned: uint,
    stake-count: uint
  }
)

(define-map user-stakes-list
  { user: principal, index: uint }
  { stake-id: uint }
)

(define-map token-gifts
  { gift-id: uint }
  {
    sender: principal,
    recipient: principal,
    amount: uint,
    message: (string-ascii 100),
    timestamp: uint
  }
)

(define-map user-gifts-sent
  { user: principal }
  { count: uint, total-amount: uint }
)

(define-map user-gifts-received
  { user: principal }
  { count: uint, total-amount: uint }
)

(define-public (create-community-challenge
  (name (string-ascii 60))
  (description (string-ascii 200))
  (challenge-type (string-ascii 20))
  (target-value uint)
  (reward-tokens uint)
  (farm-id (optional uint))
)
  (let ((challenge-id (var-get next-challenge-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> target-value u0) ERR-INVALID-AMOUNT)
    (asserts! (<= reward-tokens MAX-CHALLENGE-REWARD) ERR-INVALID-AMOUNT)
    (map-set community-challenges
      { challenge-id: challenge-id }
      {
        name: name,
        description: description,
        challenge-type: challenge-type,
        target-value: target-value,
        reward-tokens: reward-tokens,
        farm-id: farm-id,
        start-block: stacks-block-height,
        end-block: (+ stacks-block-height CHALLENGE-DURATION),
        participants: u0,
        completed: u0,
        active: true
      })
    (var-set next-challenge-id (+ challenge-id u1))
    (ok challenge-id)
  )
)

(define-public (create-seasonal-event
  (name (string-ascii 60))
  (theme (string-ascii 40))
  (description (string-ascii 250))
  (bonus-multiplier uint)
  (community-goal uint)
)
  (let ((event-id (var-get next-event-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> community-goal u0) ERR-INVALID-AMOUNT)
    (asserts! (<= bonus-multiplier u300) ERR-INVALID-AMOUNT)
    (map-set seasonal-events
      { event-id: event-id }
      {
        name: name,
        theme: theme,
        description: description,
        bonus-multiplier: bonus-multiplier,
        start-block: stacks-block-height,
        end-block: (+ stacks-block-height SEASONAL-EVENT-DURATION),
        total-participants: u0,
        community-goal: community-goal,
        current-progress: u0,
        active: true
      })
    (var-set next-event-id (+ event-id u1))
    (var-set active-seasonal-event event-id)
    (ok event-id)
  )
)

(define-public (join-challenge (challenge-id uint))
  (let 
    (
      (challenge-data (unwrap! (map-get? community-challenges { challenge-id: challenge-id }) ERR-CHALLENGE-NOT-FOUND))
      (existing-participation (map-get? user-challenge-participation { user: tx-sender, challenge-id: challenge-id }))
    )
    (asserts! (get active challenge-data) ERR-CHALLENGE-INACTIVE)
    (asserts! (< stacks-block-height (get end-block challenge-data)) ERR-CHALLENGE-EXPIRED)
    (asserts! (is-none existing-participation) ERR-ALREADY-PARTICIPATING)
    
    (map-set user-challenge-participation
      { user: tx-sender, challenge-id: challenge-id }
      {
        joined-at: stacks-block-height,
        current-progress: u0,
        completed: false,
        reward-claimed: false,
        contribution-score: u0
      })
    
    (map-set community-challenges
      { challenge-id: challenge-id }
      (merge challenge-data { participants: (+ (get participants challenge-data) u1) }))
    
    (ok true)
  )
)

(define-public (update-challenge-progress (challenge-id uint) (progress-amount uint))
  (let 
    (
      (challenge-data (unwrap! (map-get? community-challenges { challenge-id: challenge-id }) ERR-CHALLENGE-NOT-FOUND))
      (participation-data (unwrap! (map-get? user-challenge-participation { user: tx-sender, challenge-id: challenge-id }) ERR-CHALLENGE-NOT-FOUND))
    )
    (asserts! (get active challenge-data) ERR-CHALLENGE-INACTIVE)
    (asserts! (< stacks-block-height (get end-block challenge-data)) ERR-CHALLENGE-EXPIRED)
    (asserts! (not (get completed participation-data)) ERR-ALREADY-REDEEMED)
    
    (let 
      (
        (new-progress (+ (get current-progress participation-data) progress-amount))
        (target-reached (>= new-progress (get target-value challenge-data)))
      )
      (map-set user-challenge-participation
        { user: tx-sender, challenge-id: challenge-id }
        (merge participation-data 
          {
            current-progress: new-progress,
            completed: target-reached,
            contribution-score: (+ (get contribution-score participation-data) progress-amount)
          }))
      
      (if target-reached
        (map-set community-challenges
          { challenge-id: challenge-id }
          (merge challenge-data { completed: (+ (get completed challenge-data) u1) }))
        true)
      
      (var-set total-community-points (+ (var-get total-community-points) progress-amount))
      (ok new-progress)
    )
  )
)

(define-public (claim-challenge-reward (challenge-id uint))
  (let 
    (
      (challenge-data (unwrap! (map-get? community-challenges { challenge-id: challenge-id }) ERR-CHALLENGE-NOT-FOUND))
      (participation-data (unwrap! (map-get? user-challenge-participation { user: tx-sender, challenge-id: challenge-id }) ERR-CHALLENGE-NOT-FOUND))
    )
    (asserts! (get completed participation-data) ERR-ACHIEVEMENT-NOT-UNLOCKED)
    (asserts! (not (get reward-claimed participation-data)) ERR-ALREADY-REDEEMED)
    
    (let 
      (
        (base-reward (get reward-tokens challenge-data))
        (seasonal-bonus (calculate-seasonal-bonus base-reward))
        (total-reward (+ base-reward seasonal-bonus))
      )
      (try! (ft-mint? loyalty-token total-reward tx-sender))
      
      (map-set user-challenge-participation
        { user: tx-sender, challenge-id: challenge-id }
        (merge participation-data { reward-claimed: true }))
      
      (let ((current-tokens (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender }))))
        (map-set user-tokens
          { user: tx-sender }
          {
            balance: (+ (get balance current-tokens) total-reward),
            total-earned: (+ (get total-earned current-tokens) total-reward),
            total-spent: (get total-spent current-tokens)
          }))
      
      (ok total-reward)
    )
  )
)

(define-public (create-achievement
  (name (string-ascii 50))
  (description (string-ascii 150))
  (unlock-condition (string-ascii 100))
  (reward-tokens uint)
  (participants-required uint)
)
  (let ((achievement-id (+ (var-get next-challenge-id) u1000)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> participants-required u0) ERR-INVALID-AMOUNT)
    (map-set community-achievements
      { achievement-id: achievement-id }
      {
        name: name,
        description: description,
        unlock-condition: unlock-condition,
        reward-tokens: reward-tokens,
        participants-required: participants-required,
        current-participants: u0,
        unlocked: false,
        created-at: stacks-block-height
      })
    (ok achievement-id)
  )
)

(define-public (unlock-achievement (achievement-id uint))
  (let 
    (
      (achievement-data (unwrap! (map-get? community-achievements { achievement-id: achievement-id }) ERR-ACHIEVEMENT-NOT-UNLOCKED))
      (existing-unlock (map-get? user-achievements { user: tx-sender, achievement-id: achievement-id }))
    )
    (asserts! (get unlocked achievement-data) ERR-ACHIEVEMENT-NOT-UNLOCKED)
    (asserts! (is-none existing-unlock) ERR-ALREADY-REDEEMED)
    
    (let ((reward-amount (get reward-tokens achievement-data)))
      (try! (ft-mint? loyalty-token reward-amount tx-sender))
      
      (map-set user-achievements
        { user: tx-sender, achievement-id: achievement-id }
        {
          unlocked-at: stacks-block-height,
          reward-claimed: true
        })
      
      (let ((current-tokens (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender }))))
        (map-set user-tokens
          { user: tx-sender }
          {
            balance: (+ (get balance current-tokens) reward-amount),
            total-earned: (+ (get total-earned current-tokens) reward-amount),
            total-spent: (get total-spent current-tokens)
          }))
      
      (ok reward-amount)
    )
  )
)

(define-private (calculate-seasonal-bonus (base-reward uint))
  (let ((active-event-id (var-get active-seasonal-event)))
    (if (> active-event-id u0)
      (match (map-get? seasonal-events { event-id: active-event-id })
        event-data
        (if (and (get active event-data) (< stacks-block-height (get end-block event-data)))
          (/ (* base-reward (- (get bonus-multiplier event-data) u100)) u100)
          u0)
        u0)
      u0)
  )
)

(define-private (check-community-achievements (user principal) (activity-type (string-ascii 20)))
  (let ((community-points (var-get total-community-points)))
    (if (>= community-points u1000)
      (unwrap-panic (update-achievement-progress u1001 user))
      true)
    (if (is-eq activity-type "purchase")
      (unwrap-panic (update-achievement-progress u1002 user))
      true)
    (ok true)
  )
)

(define-private (update-achievement-progress (achievement-id uint) (user principal))
  (let ((achievement-data (map-get? community-achievements { achievement-id: achievement-id })))
    (match achievement-data
      data
      (if (not (get unlocked data))
        (let ((new-participants (+ (get current-participants data) u1)))
          (if (>= new-participants (get participants-required data))
            (map-set community-achievements
              { achievement-id: achievement-id }
              (merge data { current-participants: new-participants, unlocked: true }))
            (map-set community-achievements
              { achievement-id: achievement-id }
              (merge data { current-participants: new-participants })))
          (ok true))
        (ok true))
      (ok true))
  )
)

(define-private (update-active-challenges (user principal) (activity-type (string-ascii 20)) (progress uint))
  (let ((challenge-ids (list u1 u2 u3 u4 u5)))
    (fold check-and-update-challenge challenge-ids u0)
  )
)

(define-private (check-and-update-challenge (challenge-id uint) (acc uint))
  (let 
    (
      (challenge-data (map-get? community-challenges { challenge-id: challenge-id }))
      (participation-data (map-get? user-challenge-participation { user: tx-sender, challenge-id: challenge-id }))
    )
    (match challenge-data
      data
      (if (and (get active data) (< stacks-block-height (get end-block data)))
        (match participation-data
          participation
          (if (and (not (get completed participation)) (is-eq (get challenge-type data) "purchase"))
            (begin
              (unwrap-panic (update-challenge-progress challenge-id u1))
              (+ acc u1))
            acc)
          acc)
        acc)
      acc)
  )
)

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
    (unwrap-panic (check-community-achievements tx-sender "purchase"))
    (update-active-challenges tx-sender "purchase" u1)
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

(define-read-only (get-challenge-info (challenge-id uint))
  (map-get? community-challenges { challenge-id: challenge-id })
)

(define-read-only (get-seasonal-event-info (event-id uint))
  (map-get? seasonal-events { event-id: event-id })
)

(define-read-only (get-user-challenge-progress (user principal) (challenge-id uint))
  (map-get? user-challenge-participation { user: user, challenge-id: challenge-id })
)

(define-read-only (get-achievement-info (achievement-id uint))
  (map-get? community-achievements { achievement-id: achievement-id })
)

(define-read-only (get-user-achievement (user principal) (achievement-id uint))
  (map-get? user-achievements { user: user, achievement-id: achievement-id })
)

(define-read-only (get-active-seasonal-event)
  (let ((event-id (var-get active-seasonal-event)))
    (if (> event-id u0)
      (map-get? seasonal-events { event-id: event-id })
      none)
  )
)

(define-read-only (get-community-stats)
  (ok {
    total-community-points: (var-get total-community-points),
    active-seasonal-event: (var-get active-seasonal-event),
    next-challenge-id: (var-get next-challenge-id),
    next-event-id: (var-get next-event-id)
  })
)

(define-read-only (get-user-challenge-summary (user principal))
  (let ((challenge-ids (list u1 u2 u3 u4 u5)))
    (ok {
      active-challenges: (len (filter is-user-participating challenge-ids)),
      completed-challenges: (len (filter is-user-completed challenge-ids)),
      total-contribution-score: (fold sum-contribution-scores challenge-ids u0)
    })
  )
)

(define-private (is-user-participating (challenge-id uint))
  (is-some (map-get? user-challenge-participation { user: tx-sender, challenge-id: challenge-id }))
)

(define-private (is-user-completed (challenge-id uint))
  (match (map-get? user-challenge-participation { user: tx-sender, challenge-id: challenge-id })
    participation (get completed participation)
    false)
)

(define-private (sum-contribution-scores (challenge-id uint) (acc uint))
  (match (map-get? user-challenge-participation { user: tx-sender, challenge-id: challenge-id })
    participation (+ acc (get contribution-score participation))
    acc)
)

(define-read-only (get-next-challenge-id)
  (var-get next-challenge-id)
)

(define-read-only (get-next-event-id)
  (var-get next-event-id)
)

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

(define-read-only (get-stake-info (stake-id uint))
  (map-get? token-stakes { stake-id: stake-id }))

(define-read-only (get-user-stake-info (user principal))
  (default-to 
    { total-staked: u0, active-stakes: u0, total-rewards-earned: u0, stake-count: u0 }
    (map-get? user-stake-info { user: user })))

(define-read-only (get-user-stake-by-index (user principal) (index uint))
  (match (map-get? user-stakes-list { user: user, index: index })
    entry (map-get? token-stakes { stake-id: (get stake-id entry) })
    none))

(define-read-only (calculate-stake-rewards (stake-id uint))
  (match (map-get? token-stakes { stake-id: stake-id })
    stake-data
    (let 
      (
        (blocks-elapsed (- stacks-block-height (get start-block stake-data)))
        (amount (get amount stake-data))
        (apr (get apr-rate stake-data))
        (rewards (/ (* (* amount apr) blocks-elapsed) (* u10000 u52560)))
      )
      (ok rewards))
    (err ERR-STAKE-NOT-FOUND)))

(define-read-only (get-stake-tier-info (tier uint))
  (if (is-eq tier STAKE-TIER-BASIC)
    (ok { 
      tier: STAKE-TIER-BASIC, 
      apr: STAKE-APR-BASIC, 
      duration: STAKE-DURATION-BASIC,
      name: "Basic"
    })
    (if (is-eq tier STAKE-TIER-SILVER)
      (ok { 
        tier: STAKE-TIER-SILVER, 
        apr: STAKE-APR-SILVER, 
        duration: STAKE-DURATION-SILVER,
        name: "Silver"
      })
      (if (is-eq tier STAKE-TIER-GOLD)
        (ok { 
          tier: STAKE-TIER-GOLD, 
          apr: STAKE-APR-GOLD, 
          duration: STAKE-DURATION-GOLD,
          name: "Gold"
        })
        (err ERR-INVALID-STAKE-TIER)))))

(define-read-only (get-total-staked)
  (ok (var-get total-staked-tokens)))

(define-public (gift-tokens (recipient principal) (amount uint) (message (string-ascii 100)))
  (let 
    (
      (gift-id (var-get next-gift-id))
      (sender-tokens (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender })))
      (recipient-tokens (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: recipient })))
      (sender-gifts (default-to { count: u0, total-amount: u0 } (map-get? user-gifts-sent { user: tx-sender })))
      (recipient-gifts (default-to { count: u0, total-amount: u0 } (map-get? user-gifts-received { user: recipient })))
    )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (not (is-eq tx-sender recipient)) ERR-CANNOT-GIFT-SELF)
    (asserts! (>= (get balance sender-tokens) amount) ERR-INSUFFICIENT-TOKENS)

    (try! (ft-burn? loyalty-token amount tx-sender))
    (try! (ft-mint? loyalty-token amount recipient))

    (map-set token-gifts
      { gift-id: gift-id }
      {
        sender: tx-sender,
        recipient: recipient,
        amount: amount,
        message: message,
        timestamp: stacks-block-height
      })

    (map-set user-tokens
      { user: tx-sender }
      {
        balance: (- (get balance sender-tokens) amount),
        total-earned: (get total-earned sender-tokens),
        total-spent: (+ (get total-spent sender-tokens) amount)
      })

    (map-set user-tokens
      { user: recipient }
      {
        balance: (+ (get balance recipient-tokens) amount),
        total-earned: (+ (get total-earned recipient-tokens) amount),
        total-spent: (get total-spent recipient-tokens)
      })

    (map-set user-gifts-sent
      { user: tx-sender }
      { count: (+ (get count sender-gifts) u1), total-amount: (+ (get total-amount sender-gifts) amount) })

    (map-set user-gifts-received
      { user: recipient }
      { count: (+ (get count recipient-gifts) u1), total-amount: (+ (get total-amount recipient-gifts) amount) })

    (var-set next-gift-id (+ gift-id u1))
    (var-set total-gifts-sent (+ (var-get total-gifts-sent) u1))
    (ok gift-id)
  )
)

(define-public (stake-tokens (amount uint) (tier uint))
  (let 
    (
      (stake-id (var-get next-stake-id))
      (user-tokens-data (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender })))
      (user-stake-data (default-to { total-staked: u0, active-stakes: u0, total-rewards-earned: u0, stake-count: u0 } (map-get? user-stake-info { user: tx-sender })))
      (tier-info (unwrap! (get-stake-tier-info tier) ERR-INVALID-STAKE-TIER))
      (duration (get duration tier-info))
      (apr (get apr tier-info))
    )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= (get balance user-tokens-data) amount) ERR-INSUFFICIENT-STAKE-BALANCE)
    
    (try! (ft-burn? loyalty-token amount tx-sender))
    
    (map-set token-stakes
      { stake-id: stake-id }
      {
        staker: tx-sender,
        amount: amount,
        tier: tier,
        start-block: stacks-block-height,
        unlock-block: (+ stacks-block-height duration),
        apr-rate: apr,
        withdrawn: false,
        rewards-claimed: u0
      })
    
    (map-set user-stakes-list
      { user: tx-sender, index: (get stake-count user-stake-data) }
      { stake-id: stake-id })
    
    (map-set user-stake-info
      { user: tx-sender }
      {
        total-staked: (+ (get total-staked user-stake-data) amount),
        active-stakes: (+ (get active-stakes user-stake-data) u1),
        total-rewards-earned: (get total-rewards-earned user-stake-data),
        stake-count: (+ (get stake-count user-stake-data) u1)
      })
    
    (map-set user-tokens
      { user: tx-sender }
      {
        balance: (- (get balance user-tokens-data) amount),
        total-earned: (get total-earned user-tokens-data),
        total-spent: (+ (get total-spent user-tokens-data) amount)
      })
    
    (var-set next-stake-id (+ stake-id u1))
    (var-set total-staked-tokens (+ (var-get total-staked-tokens) amount))
    (ok stake-id)
  )
)

(define-public (claim-stake-rewards (stake-id uint))
  (let 
    (
      (stake-data (unwrap! (map-get? token-stakes { stake-id: stake-id }) ERR-STAKE-NOT-FOUND))
      (user-tokens-data (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender })))
      (user-stake-data (unwrap! (map-get? user-stake-info { user: tx-sender }) ERR-STAKE-NOT-FOUND))
      (rewards (unwrap! (calculate-stake-rewards stake-id) ERR-STAKE-NOT-FOUND))
    )
    (asserts! (is-eq (get staker stake-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (get withdrawn stake-data)) ERR-STAKE-ALREADY-WITHDRAWN)
    (asserts! (> rewards u0) ERR-INVALID-AMOUNT)
    
    (try! (ft-mint? loyalty-token rewards tx-sender))
    
    (map-set token-stakes
      { stake-id: stake-id }
      (merge stake-data { rewards-claimed: (+ (get rewards-claimed stake-data) rewards) }))
    
    (map-set user-stake-info
      { user: tx-sender }
      (merge user-stake-data { total-rewards-earned: (+ (get total-rewards-earned user-stake-data) rewards) }))
    
    (map-set user-tokens
      { user: tx-sender }
      {
        balance: (+ (get balance user-tokens-data) rewards),
        total-earned: (+ (get total-earned user-tokens-data) rewards),
        total-spent: (get total-spent user-tokens-data)
      })
    
    (ok rewards)
  )
)

(define-public (unstake-tokens (stake-id uint))
  (let 
    (
      (stake-data (unwrap! (map-get? token-stakes { stake-id: stake-id }) ERR-STAKE-NOT-FOUND))
      (user-tokens-data (default-to { balance: u0, total-earned: u0, total-spent: u0 } (map-get? user-tokens { user: tx-sender })))
      (user-stake-data (unwrap! (map-get? user-stake-info { user: tx-sender }) ERR-STAKE-NOT-FOUND))
      (is-unlocked (>= stacks-block-height (get unlock-block stake-data)))
      (amount (get amount stake-data))
      (penalty (if is-unlocked u0 (/ (* amount EARLY-WITHDRAWAL-PENALTY) u10000)))
      (return-amount (- amount penalty))
    )
    (asserts! (is-eq (get staker stake-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (get withdrawn stake-data)) ERR-STAKE-ALREADY-WITHDRAWN)
    
    (try! (claim-stake-rewards stake-id))
    
    (try! (ft-mint? loyalty-token return-amount tx-sender))
    
    (map-set token-stakes
      { stake-id: stake-id }
      (merge stake-data { withdrawn: true }))
    
    (map-set user-stake-info
      { user: tx-sender }
      {
        total-staked: (- (get total-staked user-stake-data) amount),
        active-stakes: (- (get active-stakes user-stake-data) u1),
        total-rewards-earned: (get total-rewards-earned user-stake-data),
        stake-count: (get stake-count user-stake-data)
      })
    
    (map-set user-tokens
      { user: tx-sender }
      {
        balance: (+ (get balance user-tokens-data) return-amount),
        total-earned: (get total-earned user-tokens-data),
        total-spent: (- (get total-spent user-tokens-data) return-amount)
      })
    
    (var-set total-staked-tokens (- (var-get total-staked-tokens) amount))
    (ok { returned: return-amount, penalty: penalty })
  )
)

(define-read-only (get-gift-info (gift-id uint))
  (map-get? token-gifts { gift-id: gift-id }))

(define-read-only (get-user-gifts-sent-info (user principal))
  (default-to { count: u0, total-amount: u0 } (map-get? user-gifts-sent { user: user })))

(define-read-only (get-user-gifts-received-info (user principal))
  (default-to { count: u0, total-amount: u0 } (map-get? user-gifts-received { user: user })))

(define-read-only (get-gifting-stats)
  (ok {
    total-gifts-sent: (var-get total-gifts-sent),
    next-gift-id: (var-get next-gift-id)
  }))
