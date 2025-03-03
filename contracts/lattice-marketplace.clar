(use-trait nft-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Storage
(define-map listings
  { token-id: uint }
  { price: uint, seller: principal }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant fee-percentage u1) ;; 1%
(define-constant min-price u1000) ;; Minimum listing price
(define-constant max-price u1000000000) ;; Maximum listing price

;; Errors
(define-constant err-not-owner (err u100))
(define-constant err-listing-exists (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-invalid-price (err u103))

;; Core functions
(define-public (list-token (token <nft-trait>) (token-id uint) (price uint))
  (let ((owner (unwrap! (contract-call? token get-owner token-id) err-not-owner)))
    (asserts! (is-eq tx-sender owner) err-not-owner)
    (asserts! (and (>= price min-price) (<= price max-price)) err-invalid-price)
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
    (metadata (unwrap! (contract-call? token get-metadata token-id) err-not-owner))
    (royalty (get royalty metadata))
    (royalty-amount (/ (* price royalty) u100))
  )
    (try! (stx-transfer? price tx-sender seller))
    (try! (stx-transfer? fee tx-sender contract-owner))
    (try! (stx-transfer? royalty-amount tx-sender (get created-by metadata)))
    (try! (contract-call? token transfer token-id seller tx-sender))
    (map-delete listings {token-id: token-id})
    (ok true)
  )
)

;; Read functions
(define-read-only (get-listing (token-id uint))
  (ok (map-get? listings {token-id: token-id}))
)
