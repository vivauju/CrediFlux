;; Peer-to-Peer Content Credibility Protocol - Stage 2
;; Enhanced with rating system and review periods

;; Constants
(define-constant ERR-NOT-ADMIN (err u1))
(define-constant ERR-PROTOCOL-PAUSED (err u2))
(define-constant ERR-INVALID-CONTENT (err u3))
(define-constant ERR-CONTENT-ALREADY-RATED (err u4))
(define-constant ERR-INVALID-RATING-PROOF (err u5))
(define-constant ERR-REVIEW-PERIOD-ACTIVE (err u6))
(define-constant ERR-INSUFFICIENT-STAKE (err u7))
(define-constant ERR-INVALID-PARAMETER (err u8))
(define-constant ERR-CONTENT-EXISTS (err u9))
(define-constant MAX-CONTENT-ID u250) ;; Increased limit

;; Data Variables
(define-data-var protocol-admin principal tx-sender)
(define-data-var protocol-active bool false)
(define-data-var current-epoch uint u0)
(define-data-var minimum-stake uint u250000) ;; 0.25 STX
(define-data-var current-block-height uint u0) ;; Block height tracking for review periods

;; Content Structure - Enhanced in Stage 2
(define-map content-registry
    uint
    {
        title: (string-utf8 256),
        content-hash: (buff 32),    
        expiration-block: uint,     ;; Review deadline (block height)
        validated: bool,
        quality-score: uint         ;; Score from 0-100
    }
)

;; Creator Profile Tracking - Extended version
(define-map creator-profiles
    principal
    {
        active-content: uint,
        validated-content: (list 20 uint), ;; Smaller list in stage 2
        last-validation: uint,
        total-validated: uint,
        reputation-score: uint      
    }
)

;; Review History - New in Stage 2
(define-map content-reviews
    {content-id: uint, reviewer: principal}
    {
        rating: uint,               ;; Score given from 0-100
        reviewed-at: uint
    }
)

;; Authorization
(define-private (is-admin)
    (is-eq tx-sender (var-get protocol-admin)))

;; Block Height Management
(define-public (update-block-height (new-height uint))
    (begin
        (asserts! (is-admin) ERR-NOT-ADMIN)
        ;; Validate height is not less than current
        (asserts! (>= new-height (var-get current-block-height)) ERR-INVALID-PARAMETER)
        (var-set current-block-height new-height)
        (ok true)))

;; Protocol Management Functions
(define-public (activate-protocol)
    (begin
        (asserts! (is-admin) ERR-NOT-ADMIN)
        (var-set protocol-active true)
        (var-set current-epoch u0)
        (ok true)))

(define-public (publish-content
    (content-id uint)
    (title (string-utf8 256))
    (content-hash (buff 32))
    (expiration-block uint))
    (begin
        ;; Validate content-id is within acceptable range
        (asserts! (<= content-id MAX-CONTENT-ID) ERR-INVALID-PARAMETER)
        
        ;; Check if content already exists to prevent overwriting
        (asserts! (is-none (map-get? content-registry content-id)) ERR-CONTENT-EXISTS)
        
        ;; Validate expiration time is in the future
        (asserts! (>= expiration-block (var-get current-block-height)) ERR-INVALID-PARAMETER)
        
        ;; Validate content hash is not empty
        (asserts! (> (len content-hash) u0) ERR-INVALID-PARAMETER)
        
        ;; Validate title is not empty
        (asserts! (> (len title) u0) ERR-INVALID-PARAMETER)
        
        ;; Set the content data
        (map-set content-registry content-id
            {
                title: title,
                content-hash: content-hash,
                expiration-block: expiration-block,
                validated: false,
                quality-score: u0
            })
            
        (ok true)))

;; Reviewer Registration
(define-public (register-as-reviewer)
    (begin
        (asserts! (var-get protocol-active) ERR-PROTOCOL-PAUSED)
        ;; Require minimum stake
        (try! (stx-transfer? (var-get minimum-stake) tx-sender (var-get protocol-admin)))
        
        ;; Initialize reviewer profile
        (map-set creator-profiles tx-sender
            {
                active-content: u0,
                validated-content: (list),
                last-validation: u0,
                total-validated: u0,
                reputation-score: u0
            })
        (ok true)))

;; Content Rating Functions - New in Stage 2
(define-public (submit-rating
    (content-id uint)
    (rating uint)
    (rating-proof (buff 32)))
    (let (
        (content (unwrap! (map-get? content-registry content-id) ERR-INVALID-CONTENT))
        (reviewer (unwrap! (map-get? creator-profiles tx-sender) ERR-INSUFFICIENT-STAKE))
        (current-block (var-get current-block-height))
        )
        ;; Check protocol status and content availability
        (asserts! (var-get protocol-active) ERR-PROTOCOL-PAUSED)
        (asserts! (>= current-block (get expiration-block content)) ERR-REVIEW-PERIOD-ACTIVE)
        (asserts! (not (get validated content)) ERR-CONTENT-ALREADY-RATED)
        
        ;; Validate rating is between 0-100
        (asserts! (<= rating u100) ERR-INVALID-PARAMETER)
        
        ;; Verify rating proof (simplified comparison)
        (if (is-eq rating-proof (get content-hash content))
            (begin
                ;; Update content status
                (map-set content-registry content-id
                    (merge content {
                        validated: true,
                        quality-score: rating
                    }))
                
                ;; Update reviewer profile
                (map-set creator-profiles tx-sender
                    (merge reviewer {
                        active-content: (+ content-id u1),
                        validated-content: (unwrap! (as-max-len? 
                            (append (get validated-content reviewer) content-id) u20)
                            ERR-INVALID-CONTENT),
                        last-validation: current-block,
                        total-validated: (+ (get total-validated reviewer) u1),
                        reputation-score: (+ (get reputation-score reviewer) u5)
                    }))
                
                ;; Record review
                (map-set content-reviews
                    {content-id: content-id, reviewer: tx-sender}
                    {
                        rating: rating,
                        reviewed-at: current-block
                    })
                
                (ok true))
            ERR-INVALID-RATING-PROOF)))

;; Read-only functions
(define-read-only (get-content-title (content-id uint))
    (match (map-get? content-registry content-id)
        content (if (>= (var-get current-block-height) (get expiration-block content))
            (ok (get title content))
            ERR-REVIEW-PERIOD-ACTIVE)
        ERR-INVALID-CONTENT))

(define-read-only (get-creator-profile (creator principal))
    (map-get? creator-profiles creator))

(define-read-only (get-current-block)
    (var-get current-block-height))

(define-read-only (get-protocol-metrics)
    {
        active: (var-get protocol-active),
        current-epoch: (var-get current-epoch),
        minimum-stake: (var-get minimum-stake),
        current-block-height: (var-get current-block-height)
    })

(define-public (update-minimum-stake (new-minimum uint))
    (begin
        (asserts! (is-admin) ERR-NOT-ADMIN)
        (var-set minimum-stake new-minimum)
        (ok true)))

(define-public (pause-protocol)
    (begin
        (asserts! (is-admin) ERR-NOT-ADMIN)
        (var-set protocol-active false)
        (ok true)))

(define-public (advance-epoch)
    (begin
        (asserts! (is-admin) ERR-NOT-ADMIN)
        (asserts! (var-get protocol-active) ERR-PROTOCOL-PAUSED)
        (var-set current-epoch (+ (var-get current-epoch) u1))
        (ok true)))

(define-public (transfer-admin-role (new-admin principal))
    (begin
        (asserts! (is-admin) ERR-NOT-ADMIN)
        (var-set protocol-admin new-admin)
        (ok true)))