;; Peer-to-Peer Content Credibility Protocol 

;; Constants
(define-constant ERR-NOT-ADMIN (err u1))
(define-constant ERR-PROTOCOL-PAUSED (err u2))
(define-constant ERR-INVALID-CONTENT (err u3))
(define-constant ERR-INVALID-PARAMETER (err u8))
(define-constant ERR-CONTENT-EXISTS (err u9))
(define-constant MAX-CONTENT-ID u100) ;; Starting with a smaller limit

;; Data Variables
(define-data-var protocol-admin principal tx-sender)
(define-data-var protocol-active bool false)
(define-data-var current-epoch uint u0)
(define-data-var minimum-stake uint u100000) ;; 0.1 STX initial value

;; Content Structure - Simplified in Stage 1
(define-map content-registry
    uint
    {
        title: (string-utf8 256),
        content-hash: (buff 32),
        validated: bool
    }
)

;; Creator Profile Tracking - Basic version
(define-map creator-profiles
    principal
    {
        active-content: uint,
        total-validated: uint
    }
)

;; Authorization
(define-private (is-admin)
    (is-eq tx-sender (var-get protocol-admin)))

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
    (content-hash (buff 32)))
    (begin
        ;; Validate content-id is within acceptable range
        (asserts! (<= content-id MAX-CONTENT-ID) ERR-INVALID-PARAMETER)
        
        ;; Check if content already exists to prevent overwriting
        (asserts! (is-none (map-get? content-registry content-id)) ERR-CONTENT-EXISTS)
        
        ;; Validate content hash is not empty
        (asserts! (> (len content-hash) u0) ERR-INVALID-PARAMETER)
        
        ;; Validate title is not empty
        (asserts! (> (len title) u0) ERR-INVALID-PARAMETER)
        
        ;; Set the content data
        (map-set content-registry content-id
            {
                title: title,
                content-hash: content-hash,
                validated: false
            })
            
        (ok true)))

;; Reviewer Registration - Simple version
(define-public (register-as-reviewer)
    (begin
        (asserts! (var-get protocol-active) ERR-PROTOCOL-PAUSED)
        ;; Require minimum stake
        (try! (stx-transfer? (var-get minimum-stake) tx-sender (var-get protocol-admin)))
        
        ;; Initialize reviewer profile
        (map-set creator-profiles tx-sender
            {
                active-content: u0,
                total-validated: u0
            })
        (ok true)))

;; Read-only functions
(define-read-only (get-content-details (content-id uint))
    (map-get? content-registry content-id))

(define-read-only (get-creator-profile (creator principal))
    (map-get? creator-profiles creator))

(define-read-only (get-protocol-status)
    {
        active: (var-get protocol-active),
        current-epoch: (var-get current-epoch),
        minimum-stake: (var-get minimum-stake)
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

(define-public (transfer-admin-role (new-admin principal))
    (begin
        (asserts! (is-admin) ERR-NOT-ADMIN)
        (var-set protocol-admin new-admin)
        (ok true)))