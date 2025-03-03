# ZenTrek
A mindfulness app that pairs nature sounds with daily breathing exercises on the Stacks blockchain.

## Features
- Create and store breathing exercise routines 
- Associate nature sounds with exercises
- Track user completion of daily exercises
- Reward system for consistent practice

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a new breathing exercise
(contract-call? .zentrek create-exercise "Ocean Breaths" "Deep ocean waves" u300)

;; Log exercise completion
(contract-call? .zentrek complete-exercise u1)

;; Get user stats
(contract-call? .zentrek get-user-stats tx-sender)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
