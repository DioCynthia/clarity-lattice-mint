(use-trait nft-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Storage
(define-map listings
  { token-id: uint }
  { price: uint, seller: principal }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant fee-percentage u1) ;; 1%

;; Errors
(define-constant err-not-owner (err u100))
(define-constant err-listing-exists (err u101))
(define-constant err-listing-not-found (err u102))

;; Core functions
(define-public (list-token (token <nft-trait>) (token-id uint) (price uint))
  (let ((owner (unwrap! (contract-call? token get-owner token-id) err-not-owner)))
    (asserts! (is-eq tx-sender owner) err-not-owner)
    (asserts! (is-none (map-get? listings {token-id: token-id})) err-listing-exists)
    (map-set listings 
      {token-id: token-id}
      {price: price, seller: tx-sender}
    )
    (ok true)
  )
)

(define-public (purchase (token <nft-trait>) (token-id uint))
  (let (
    (listing (unwrap! (map-get? listings {token-id: token-id}) err-listing-not-found))
    (price (get price listing))
    (seller (get seller listing))
    (fee (/ (* price fee-percentage) u100))
  )
    (try! (stx-transfer? price tx-sender seller))
    (try! (stx-transfer? fee tx-sender contract-owner))
    (try! (contract-call? token transfer token-id seller tx-sender))
    (map-delete listings {token-id: token-id})
    (ok true)
  )
)

(define-public (cancel-listing (token-id uint))
  (let ((listing (unwrap! (map-get? listings {token-id: token-id}) err-listing-not-found)))
    (asserts! (is-eq tx-sender (get seller listing)) err-not-owner)
    (map-delete listings {token-id: token-id})
    (ok true)
  )
)

;; Read functions
(define-read-only (get-listing (token-id uint))
  (ok (map-get? listings {token-id: token-id}))
)
