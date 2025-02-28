;; ZenTrek Contract
;; Mindfulness app pairing nature sounds with breathing exercises

;; Data Structures
(define-map exercises
  { exercise-id: uint }
  {
    name: (string-ascii 50),
    sound: (string-ascii 50),
    duration: uint,
    creator: principal
  }
)

(define-map user-stats
  { user: principal }
  {
    exercises-completed: uint,
    last-exercise: uint,
    streak: uint
  }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-owner-only (err u101))
(define-constant err-invalid-duration (err u102))

;; Data Variables
(define-data-var exercise-counter uint u0)

;; Public Functions
(define-public (create-exercise (name (string-ascii 50)) (sound (string-ascii 50)) (duration uint))
  (let 
    (
      (exercise-id (+ (var-get exercise-counter) u1))
    )
    (if (> duration u0)
      (begin
        (map-set exercises
          { exercise-id: exercise-id }
          {
            name: name,
            sound: sound,
            duration: duration,
            creator: tx-sender
          }
        )
        (var-set exercise-counter exercise-id)
        (ok exercise-id)
      )
      err-invalid-duration
    )
  )
)

(define-public (complete-exercise (exercise-id uint))
  (let
    (
      (user-stat (default-to
        { exercises-completed: u0, last-exercise: u0, streak: u0 }
        (map-get? user-stats { user: tx-sender })
      ))
    )
    (if (map-get? exercises { exercise-id: exercise-id })
      (begin
        (map-set user-stats
          { user: tx-sender }
          {
            exercises-completed: (+ (get exercises-completed user-stat) u1),
            last-exercise: exercise-id,
            streak: (+ (get streak user-stat) u1)
          }
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Read Only Functions
(define-read-only (get-exercise (exercise-id uint))
  (ok (map-get? exercises { exercise-id: exercise-id }))
)

(define-read-only (get-user-stats (user principal))
  (ok (map-get? user-stats { user: user }))
)
