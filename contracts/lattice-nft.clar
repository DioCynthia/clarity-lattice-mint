;; Implements SIP-009 NFT trait
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Token definitions
(define-non-fungible-token lattice-nft uint)

;; Storage
(define-map token-metadata uint {
  points: (list 100 uint),
  connections: (list 100 uint),
  dimensions: uint,
  created-by: principal,
  created-at: uint,
  royalty: uint
})

(define-map mint-count principal uint)
(define-data-var last-token-id uint u0)
(define-data-var is-paused bool false)

;; Constants  
(define-constant contract-owner tx-sender)
(define-constant mint-price u100000) ;; 0.1 STX
(define-constant max-mint-per-user u10)
(define-constant default-royalty u5) ;; 5%

;; Errors
(define-constant err-not-owner (err u100))
(define-constant err-token-exists (err u101))
(define-constant err-invalid-params (err u102))
(define-constant err-mint-limit (err u103))
(define-constant err-paused (err u104))

;; Core functions
(define-public (mint (points (list 100 uint)) (connections (list 100 uint)) (dimensions uint))
  (let 
    (
      (token-id (+ (var-get last-token-id) u1))
      (current-count (default-to u0 (map-get? mint-count tx-sender)))
    )
    (asserts! (not (var-get is-paused)) err-paused)
    (asserts! (< current-count max-mint-per-user) err-mint-limit)
    (asserts! (is-valid-lattice points connections dimensions) err-invalid-params)
    (try! (stx-transfer? mint-price tx-sender contract-owner))
    (try! (nft-mint? lattice-nft token-id tx-sender))
    (map-set token-metadata token-id {
      points: points,
      connections: connections,
      dimensions: dimensions,
      created-by: tx-sender,
      created-at: block-height,
      royalty: default-royalty
    })
    (map-set mint-count tx-sender (+ current-count u1))
    (var-set last-token-id token-id)
    (ok token-id)
  )
)

;; Admin functions
(define-public (set-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (var-set is-paused paused)
    (ok true)
  )
)

;; Enhanced transfer with royalty handling
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-owner)
    (nft-transfer? lattice-nft token-id sender recipient)
  )
)

;; Read functions  
(define-read-only (get-token-uri (token-id uint))
  (ok (some (concat "https://lattice-mint.xyz/metadata/" (uint-to-string token-id))))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? lattice-nft token-id))
)

(define-read-only (get-metadata (token-id uint))
  (ok (map-get? token-metadata token-id))
)

;; Internal helpers
(define-private (is-valid-lattice (points (list 100 uint)) (connections (list 100 uint)) (dimensions uint))
  (and
    (> (len points) u0)
    (> (len connections) u0) 
    (>= dimensions u2)
    (<= dimensions u10)
  )
)
