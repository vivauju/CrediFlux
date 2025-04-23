# CrediFlux

**CrediFlux** is a decentralized peer-to-peer content credibility and reputation protocol built on the [Stacks blockchain](https://stacks.co/), enabling users to verify, rate, and reward digital content transparently. The protocol is designed to combat misinformation, reward high-quality contributions, and build decentralized reputational trust.

---

## 🎯 Key Features

- 🔐 **On-chain Content Validation**: Users publish hashed content references that are validated by community reviewers.
- ⭐ **Decentralized Reputation System**: Reviewers earn scores and STX rewards based on participation and accurate validation.
- ⏱️ **Timed Review Periods**: Each content piece has a finite window for review, after which it is permanently rated and finalized.
- 💰 **Tokenized Incentives**: Content creators deposit STX rewards which are proportionally distributed to honest reviewers.
- 👁️ **Transparent Review Analytics**: Publicly viewable data on how each piece was reviewed and by whom.

---

## 🛠️ Smart Contract Overview

This protocol is implemented in [Clarity](https://docs.stacks.co/docs/write-smart-contracts/clarity-overview), a predictable and secure language for smart contracts on Bitcoin via the Stacks blockchain.

### Core Modules

- **Content Registry**: Registers content by ID, title, hash, review deadline, and reward.
- **Reviewer Profiles**: Tracks active participation, validated submissions, and reputation.
- **Rating Engine**: Validates reviewer submissions and computes reward distribution.
- **Analytics**: Stores a limited history of reviewer activity for each content.
- **Governance**: Admin functions for epoch control, staking threshold, and protocol state.

---

## 🧩 Data Structures

| Map Name              | Description                                  |
|-----------------------|----------------------------------------------|
| `content-registry`    | Stores each content submission's metadata.   |
| `creator-profiles`    | Maintains data on reviewer participation.    |
| `content-reviews`     | Tracks individual ratings and reward claims. |
| `review-analytics`    | Recent history of reviews per content.       |

---

## 🔐 Admin & Governance

| Function                   | Description                                     |
|----------------------------|-------------------------------------------------|
| `activate-protocol`        | Starts the protocol lifecycle.                 |
| `pause-protocol`           | Freezes all participation.                     |
| `advance-epoch`            | Manually moves to a new epoch.                 |
| `update-block-height`      | Admin update to the current block context.     |
| `update-minimum-stake`     | Sets staking requirement for reviewers.        |
| `transfer-admin-role`      | Transfers admin rights.                        |

---

## 💬 User Flow

1. **Creator publishes content** with a unique `content-id`, title, SHA256 hash, reward pool, and review deadline.
2. **Reviewers register** by staking a minimum amount of STX.
3. **Content is reviewed** after its expiration block passes, using a verified proof-of-rating hash.
4. **Ratings are submitted**, content is marked validated, and quality scores are assigned.
5. **Reviewers claim rewards** based on the quality and weight of their input.

---

## ⚠️ Error Codes

| Error Constant             | Meaning                                |
|----------------------------|----------------------------------------|
| `ERR-NOT-ADMIN`            | Action requires admin privileges.     |
| `ERR-PROTOCOL-PAUSED`      | Protocol is currently inactive.       |
| `ERR-INVALID-CONTENT`      | Content does not exist.               |
| `ERR-CONTENT-ALREADY-RATED`| Content has already been validated.   |
| `ERR-INVALID-RATING-PROOF` | Rating hash does not match content.  |
| `ERR-REVIEW-PERIOD-ACTIVE` | Review window still active.           |
| `ERR-INSUFFICIENT-STAKE`   | Reviewer did not stake minimum.       |
| `ERR-INVALID-PARAMETER`    | Input failed validation check.        |
| `ERR-CONTENT-EXISTS`       | Content ID already registered.        |

---

## 🧪 Example Interaction (Simplified)

```lisp
;; Admin activates the protocol
(activate-protocol)

;; Creator submits content with ID 1
(publish-content u1 "Decentralized Truth" 0xabc123... u10000 u1000000)

;; Reviewer stakes to register
(register-as-reviewer)

;; After expiration block...
(submit-rating u1 u85 0xabc123...)

;; Reviewer claims reward
(claim-review-reward u1)
```

---

## 🔮 Future Enhancements

- 🔍 **Zero-Knowledge Rating Proofs** for privacy-preserving validations.
- 🧠 **Machine Learning-Assisted Pre-Rating** to guide reviewers.
- 🧱 **NFT Badge System** for top contributors and reviewers.
- 🌐 **Web UI DApp** to simplify interactions with the protocol.
