(define-fungible-token fleet-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-asset-exists (err u104))
(define-constant err-asset-not-active (err u105))
(define-constant err-unauthorized (err u106))
(define-constant err-invalid-percentage (err u107))

(define-data-var next-asset-id uint u1)
(define-data-var total-revenue uint u0)

(define-map assets 
  uint
  {
    owner: principal,
    asset-type: (string-ascii 20),
    model: (string-ascii 50),
    license-plate: (string-ascii 20),
    daily-revenue: uint,
    token-supply: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map asset-tokens
  { asset-id: uint, holder: principal }
  uint
)

(define-map revenue-pool
  uint
  uint
)

(define-map last-claim
  { asset-id: uint, holder: principal }
  uint
)

(define-map asset-holders
  uint
  (list 100 principal)
)

(define-public (register-asset (asset-type (string-ascii 20)) 
                               (model (string-ascii 50))
                               (license-plate (string-ascii 20))
                               (daily-revenue uint)
                               (token-supply uint))
  (let ((asset-id (var-get next-asset-id)))
    (asserts! (> token-supply u0) err-invalid-amount)
    (asserts! (> daily-revenue u0) err-invalid-amount)
    (map-set assets asset-id {
      owner: tx-sender,
      asset-type: asset-type,
      model: model,
      license-plate: license-plate,
      daily-revenue: daily-revenue,
      token-supply: token-supply,
      is-active: true,
      created-at: stacks-block-height
    })
    (try! (ft-mint? fleet-token token-supply tx-sender))
    (map-set asset-tokens { asset-id: asset-id, holder: tx-sender } token-supply)
    (map-set asset-holders asset-id (list tx-sender))
    (var-set next-asset-id (+ asset-id u1))
    (ok asset-id)
  )
)

(define-public (purchase-tokens (asset-id uint) (amount uint) (price uint))
  (let ((asset (unwrap! (map-get? assets asset-id) err-not-found)))
    (asserts! (get is-active asset) err-asset-not-active)
    (asserts! (> amount u0) err-invalid-amount)
    (let ((seller (get owner asset)))
      (try! (stx-transfer? price tx-sender seller))
      (try! (ft-transfer? fleet-token amount seller tx-sender))
      (let ((current-tokens (default-to u0 (map-get? asset-tokens { asset-id: asset-id, holder: tx-sender }))))
        (map-set asset-tokens { asset-id: asset-id, holder: tx-sender } (+ current-tokens amount))
        (let ((seller-tokens (default-to u0 (map-get? asset-tokens { asset-id: asset-id, holder: seller }))))
          (map-set asset-tokens { asset-id: asset-id, holder: seller } (- seller-tokens amount))
          (let ((holders (default-to (list) (map-get? asset-holders asset-id))))
            (if (is-none (index-of holders tx-sender))
              (map-set asset-holders asset-id (unwrap! (as-max-len? (append holders tx-sender) u100) err-invalid-amount))
              true
            )
          )
        )
      )
      (ok true)
    )
  )
)

(define-public (add-revenue (asset-id uint) (amount uint))
  (let ((asset (unwrap! (map-get? assets asset-id) err-not-found)))
    (asserts! (is-eq tx-sender (get owner asset)) err-unauthorized)
    (asserts! (get is-active asset) err-asset-not-active)
    (asserts! (> amount u0) err-invalid-amount)
    (let ((current-pool (default-to u0 (map-get? revenue-pool asset-id))))
      (map-set revenue-pool asset-id (+ current-pool amount))
      (var-set total-revenue (+ (var-get total-revenue) amount))
      (ok true)
    )
  )
)

(define-public (claim-revenue (asset-id uint))
  (let ((asset (unwrap! (map-get? assets asset-id) err-not-found))
        (user-tokens (default-to u0 (map-get? asset-tokens { asset-id: asset-id, holder: tx-sender })))
        (total-tokens (get token-supply asset))
        (revenue-available (default-to u0 (map-get? revenue-pool asset-id))))
    (asserts! (> user-tokens u0) err-insufficient-balance)
    (asserts! (> revenue-available u0) err-insufficient-balance)
    (let ((user-share (/ (* revenue-available user-tokens) total-tokens))
          (last-claim-block (default-to u0 (map-get? last-claim { asset-id: asset-id, holder: tx-sender }))))
      (asserts! (> stacks-block-height (+ last-claim-block u144)) err-unauthorized)
      (try! (as-contract (stx-transfer? user-share (as-contract tx-sender) tx-sender)))
      (map-set last-claim { asset-id: asset-id, holder: tx-sender } stacks-block-height)
      (map-set revenue-pool asset-id (- revenue-available user-share))
      (ok user-share)
    )
  )
)

(define-public (transfer-asset-tokens (asset-id uint) (amount uint) (recipient principal))
  (let ((sender-tokens (default-to u0 (map-get? asset-tokens { asset-id: asset-id, holder: tx-sender }))))
    (asserts! (>= sender-tokens amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-amount)
    (try! (ft-transfer? fleet-token amount tx-sender recipient))
    (map-set asset-tokens { asset-id: asset-id, holder: tx-sender } (- sender-tokens amount))
    (let ((recipient-tokens (default-to u0 (map-get? asset-tokens { asset-id: asset-id, holder: recipient }))))
      (map-set asset-tokens { asset-id: asset-id, holder: recipient } (+ recipient-tokens amount))
      (let ((holders (default-to (list) (map-get? asset-holders asset-id))))
        (if (is-none (index-of holders recipient))
          (map-set asset-holders asset-id (unwrap! (as-max-len? (append holders recipient) u100) err-invalid-amount))
          true
        )
      )
    )
    (ok true)
  )
)

(define-public (deactivate-asset (asset-id uint))
  (let ((asset (unwrap! (map-get? assets asset-id) err-not-found)))
    (asserts! (is-eq tx-sender (get owner asset)) err-unauthorized)
    (map-set assets asset-id (merge asset { is-active: false }))
    (ok true)
  )
)

(define-public (update-daily-revenue (asset-id uint) (new-revenue uint))
  (let ((asset (unwrap! (map-get? assets asset-id) err-not-found)))
    (asserts! (is-eq tx-sender (get owner asset)) err-unauthorized)
    (asserts! (> new-revenue u0) err-invalid-amount)
    (map-set assets asset-id (merge asset { daily-revenue: new-revenue }))
    (ok true)
  )
)

(define-read-only (get-asset (asset-id uint))
  (map-get? assets asset-id)
)

(define-read-only (get-asset-tokens (asset-id uint) (holder principal))
  (map-get? asset-tokens { asset-id: asset-id, holder: holder })
)

(define-read-only (get-revenue-pool (asset-id uint))
  (map-get? revenue-pool asset-id)
)

(define-read-only (get-user-claimable-revenue (asset-id uint) (holder principal))
  (match (map-get? assets asset-id)
    asset (let ((user-tokens (default-to u0 (map-get? asset-tokens { asset-id: asset-id, holder: holder })))
                (total-tokens (get token-supply asset))
                (revenue-available (default-to u0 (map-get? revenue-pool asset-id))))
            (if (> user-tokens u0)
              (some (/ (* revenue-available user-tokens) total-tokens))
              (some u0)))
    none
  )
)

(define-read-only (get-asset-holders (asset-id uint))
  (map-get? asset-holders asset-id)
)

(define-read-only (get-total-assets)
  (- (var-get next-asset-id) u1)
)

(define-read-only (get-total-revenue)
  (var-get total-revenue)
)

(define-read-only (get-last-claim (asset-id uint) (holder principal))
  (map-get? last-claim { asset-id: asset-id, holder: holder })
)

(define-read-only (can-claim-revenue (asset-id uint) (holder principal))
  (let ((last-claim-block (default-to u0 (map-get? last-claim { asset-id: asset-id, holder: holder }))))
    (> stacks-block-height (+ last-claim-block u144))
  )
)
