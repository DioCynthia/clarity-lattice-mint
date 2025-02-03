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
  created-at: uint
})

(define-data-var last-token-id uint u0)

;; Constants  
(define-constant contract-owner tx-sender)
(define-constant mint-price u100000) ;; 0.1 STX

;; Errors
(define-constant err-not-owner (err u100))
(define-constant err-token-exists (err u101))
(define-constant err-invalid-params (err u102))

;; Core functions
(define-public (mint (points (list 100 uint)) (connections (list 100 uint)) (dimensions uint))
  (let 
    (
      (token-id (+ (var-get last-token-id) u1))
    )
    (asserts! (is-valid-lattice points connections dimensions) err-invalid-params)
    (try! (stx-transfer? mint-price tx-sender contract-owner))
    (try! (nft-mint? lattice-nft token-id tx-sender))
    (map-set token-metadata token-id {
      points: points,
      connections: connections,
      dimensions: dimensions,
      created-by: tx-sender,
      created-at: block-height
    })
    (var-set last-token-id token-id)
    (ok token-id)
  )
)

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
  )
)
