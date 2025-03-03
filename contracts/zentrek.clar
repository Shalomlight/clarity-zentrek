;; ZenTrek Contract
;; Mindfulness app pairing nature sounds with breathing exercises

;; Data Structures
(define-map exercises
  { exercise-id: uint }
  {
    name: (string-ascii 50),
    sound: (string-ascii 50),
    duration: uint,
    creator: principal,
    created-at: uint
  }
)

(define-map user-stats
  { user: principal }
  {
    exercises-completed: uint,
    last-exercise: uint,
    last-completion-time: uint,
    streak: uint
  }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-owner-only (err u101))
(define-constant err-invalid-duration (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-not-authorized (err u104))
(define-constant max-duration u3600) ;; 1 hour max
(define-constant streak-window u86400) ;; 24 hours in seconds

;; Data Variables
(define-data-var exercise-counter uint u0)
(define-data-var total-participants uint u0)
(define-data-var contract-paused bool false)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (validate-input (name (string-ascii 50)) (sound (string-ascii 50)) (duration uint))
  (and
    (not (is-eq name ""))
    (not (is-eq sound ""))
    (and (> duration u0) (<= duration max-duration))
  )
)

;; Public Functions
(define-public (create-exercise (name (string-ascii 50)) (sound (string-ascii 50)) (duration uint))
  (let 
    (
      (exercise-id (+ (var-get exercise-counter) u1))
    )
    (if (validate-input name sound duration)
      (begin
        (map-set exercises
          { exercise-id: exercise-id }
          {
            name: name,
            sound: sound,
            duration: duration,
            creator: tx-sender,
            created-at: block-height
          }
        )
        (var-set exercise-counter exercise-id)
        (ok exercise-id)
      )
      err-invalid-input
    )
  )
)

(define-public (modify-exercise (exercise-id uint) (name (string-ascii 50)) (sound (string-ascii 50)) (duration uint))
  (let
    (
      (exercise (unwrap! (map-get? exercises { exercise-id: exercise-id }) err-not-found))
    )
    (if (and
          (is-eq (get creator exercise) tx-sender)
          (validate-input name sound duration)
        )
      (begin
        (map-set exercises
          { exercise-id: exercise-id }
          {
            name: name,
            sound: sound,
            duration: duration,
            creator: tx-sender,
            created-at: (get created-at exercise)
          }
        )
        (ok true)
      )
      err-not-authorized
    )
  )
)

(define-public (complete-exercise (exercise-id uint))
  (let
    (
      (exercise (unwrap! (map-get? exercises { exercise-id: exercise-id }) err-not-found))
      (current-time block-height)
      (user-stat (default-to
        { exercises-completed: u0, last-exercise: u0, last-completion-time: u0, streak: u0 }
        (map-get? user-stats { user: tx-sender })
      ))
      (last-completion (get last-completion-time user-stat))
      (new-streak (if (< (- current-time last-completion) streak-window)
        (+ (get streak user-stat) u1)
        u1))
    )
    (begin
      (map-set user-stats
        { user: tx-sender }
        {
          exercises-completed: (+ (get exercises-completed user-stat) u1),
          last-exercise: exercise-id,
          last-completion-time: current-time,
          streak: new-streak
        }
      )
      (if (is-eq (get exercises-completed user-stat) u0)
        (var-set total-participants (+ (var-get total-participants) u1))
        true
      )
      (ok true)
    )
  )
)

;; Contract Management
(define-public (pause-contract)
  (if (is-contract-owner)
    (begin
      (var-set contract-paused true)
      (ok true)
    )
    err-owner-only
  )
)

(define-public (unpause-contract)
  (if (is-contract-owner)
    (begin
      (var-set contract-paused false)
      (ok true)
    )
    err-owner-only
  )
)

;; Read Only Functions
(define-read-only (get-exercise (exercise-id uint))
  (ok (map-get? exercises { exercise-id: exercise-id }))
)

(define-read-only (get-user-stats (user principal))
  (ok (map-get? user-stats { user: user }))
)

(define-read-only (get-total-participants)
  (ok (var-get total-participants))
)

(define-read-only (is-paused)
  (ok (var-get contract-paused))
)
