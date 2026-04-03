---
title: Designing a real-time text system
---

# Designing a real-time text system

This page covers the design of real-time text (RTT) systems – systems where a sender's keystrokes are transmitted to recipients as they are typed. RTT is distinct from collaborative document editing (which uses techniques like operational transformation and CRDTs to reconcile concurrent edits): in RTT, only one party authors a message at a time, so no conflict resolution is needed.

## 1. Prior work

- 1998: [ITU-T T.140: Protocol for multimedia application text conversation](https://www.itu.int/rec/T-REC-T.140/en)
  [[Mirror](/docs/T-REC-T.140-199802-I!!PDF-E.pdf)] [[Mirror of addendum](/docs/T-REC-T.140-200002-I!Add1!PDF-E.pdf)]
- 2005: [IETF RFC 4103: RTP Payload for Text Conversation](https://www.rfc-editor.org/rfc/rfc4103.txt) [[Mirror](/docs/rfc4103.txt)]
- 2008: [IETF RFC 5194: Framework for Real-Time Text over IP Using the Session Initiation Protocol (SIP)](https://www.rfc-editor.org/rfc/rfc5194.txt) [[Mirror](/docs/rfc5194.txt)]
- 2013: [XEP-0301: In-Band Real Time Text](https://xmpp.org/extensions/xep-0301.html) [[HTML mirror](/docs/xep-0301.mhtml)] [[PDF mirror](/docs/xep-0301.pdf)]

## 2. Considerations

When designing a real-time text system, consider the following factors:

Transport protocol
: What does the real-time text protocol run over? TCP guarantees ordering and delivery at the cost of latency (retransmissions block subsequent data). UDP is "fire and forget." Lower latency, but the protocol itself must handle packet loss and ordering. WebSocket is a common choice for browser-based systems, providing a persistent full-duplex channel over TCP.

Correctness and recoverability
: Should the receiver's copy of the message always match the sender's exactly, or is occasional divergence acceptable? What happens when the connection drops mid-message – is the partial message preserved or lost? If the receiver falls out of sync (due to packet loss or a reconnection), how is the correct state restored? The answers depend on the transmission approach (see section 3).

Update frequency
: How often are updates transmitted? More frequent updates (e.g., on every keystroke) feel more responsive but consume more bandwidth. Less frequent updates (e.g., batched at fixed intervals) are more efficient but introduce perceptible delay. XEP-0301 recommends 700-millisecond intervals as a balance between responsiveness and overhead.

Bandwidth and scalability
: Bandwidth cost depends on the transmission approach (see section 3), update frequency, and message length. An approach that transmits the entire message on every change (3.2) is cheap for short messages but expensive for long ones. A diff-based approach (3.3) scales better with message length but adds complexity. Consider the expected message sizes, number of concurrent conversations, and available bandwidth.

Protocol flexibility
: Can the protocol be extended to accommodate features like rich text, emojis, media attachments, replies, user tagging, and so on? A protocol that transmits opaque text blobs (3.2) may be easier to extend than one that transmits granular character-level operations (3.1).

Platform
: Browser-based systems are limited to WebSocket or HTTP-based transports and have weaker cryptographic guarantees. Desktop clients have more flexibility in transport and encryption. Mobile clients must account for intermittent connectivity and background process restrictions.

## 3. Transmission approaches

There are at least three approaches to transmitting real-time text, differing in bandwidth cost, complexity, and resilience to packet loss. All three require some way to signal the end of a message (a "send" action) in addition to the in-progress updates.

### 3.1. Transmit exact keystrokes

The sender transmits each character (or small batch of characters) as it is typed. The receiver appends incoming characters to reconstruct the message.

- Minimal bandwidth: only new characters are sent.
- Simple to implement on both sender and receiver.
- Mid-message edits (the sender repositions the cursor, or presses backspace) can be represented by including control characters such as backspace and delete in the character stream, as T.140 does. However, this model cannot efficiently express arbitrary edits like jumping to a specific position and inserting text; for that, see 3.3.
- Not self-repairing: a lost packet permanently corrupts the receiver's copy unless the protocol includes a recovery mechanism. Over UDP, redundancy can be added by retransmitting recently sent characters in each packet, so that a lost packet is covered by the next one. RFC 4103 does this, including two redundant generations of previous text in each RTP packet by default. Over TCP, delivery is guaranteed but retransmission delays may introduce latency spikes.
- Bandwidth can be reduced further by batching characters and transmitting them at a fixed interval rather than one-by-one.

### 3.2. Transmit entire message

On every change, the sender transmits the full current text of the message. The receiver replaces its displayed text with each incoming update.

- Self-repairing: every update is a complete snapshot, so a lost packet is always superseded by the next one. Well-suited for unreliable transports.
- Simplest to implement: the receiver only needs to display whatever it last received.
- Most bandwidth-intensive. Cost grows linearly with message length: a single keystroke appended to a long message still retransmits the entire text. May be acceptable for short messages but scales poorly.
- Handles all edit types (mid-message insertions, deletions, cursor jumps) implicitly, since the receiver always gets the complete result.

### 3.3. Transmit a diff

The sender transmits only what changed since the last update: insertions, deletions, and optionally cursor movements. The receiver applies these operations to its local copy of the message.

- Bandwidth-efficient: cost is proportional to the size of each edit, not the size of the message.
- Can directly represent arbitrary edits: mid-message insertions, deletions, and cursor repositioning.
- More complex to implement. Both sender and receiver must maintain synchronized state, and the sender must compute the diff between consecutive message states.
- Not self-repairing: if a diff is lost or applied incorrectly, the receiver's state diverges from the sender's. A recovery mechanism is needed, e.g. periodically retransmitting the full message state so the receiver can resynchronize. XEP-0301 does this with a "reset" event (recommended every 10 seconds) that retransmits the complete message.
- XEP-0301 defines three action elements: text insertion (`<t/>`), text erasure (`<e/>`), and wait intervals (`<w/>`, to preserve typing rhythm). Actions are batched and transmitted at a recommended interval of 700 milliseconds.

## 4. Message association

Every update needs enough information to identify the sender and the message it belongs to. Supplementary data – attachments, emoji, reply references, tagged users – can be sent once at the point it is added and omitted from subsequent updates. Receiving clients keep this data in memory alongside the in-progress message. If the update carrying it is lost, the receiver will miss it, but including it again in the finalization packet provides a fallback.

## 5. Encryption

Key establishment is out of scope for this page. The following assumes that participants in an encrypted RTT channel have agreed on a shared key for encrypting and decrypting message payloads.

### 5.1. Transport encryption vs end-to-end encryption

Transport encryption (TLS, WSS) protects data in transit between client and server, but the server sees plaintext. End-to-end encryption (E2EE) keeps message content private from the server as well, but complicates server-side functionality such as search, moderation, spam filtering, and push notification previews. RTT's high update frequency amplifies the cost of E2EE: each update must be encrypted and decrypted at both ends, and the server must relay ciphertext it cannot inspect.

### 5.2. Cipher choice

A stream cipher (or a block cipher in a streaming mode such as CTR or GCM) is a natural fit for RTT, where updates are small and arrive incrementally. Block ciphers in modes like CBC require input to be padded to a fixed block size, adding overhead to every small update: a single character encrypted with AES-128-CBC still produces at least 16 bytes of ciphertext plus a 16-byte IV.

### 5.3. Traffic analysis

Encryption protects message content, but RTT traffic is unusually vulnerable to metadata analysis. Even without decrypting any payload, an observer of encrypted RTT traffic can see:

- **Packet timing**: when each update is sent, revealing inter-keystroke intervals.
- **Packet size**: how large each update is, hinting at how much text was added or removed.
- **Packet frequency**: whether the sender is actively typing, pausing, or idle.

From this metadata alone, an attacker can potentially infer:

- **Word and sentence boundaries**: longer pauses between keystrokes tend to coincide with word and sentence boundaries.
- **Corrections**: bursts of small packets may indicate backspacing and retyping.
- **Message length**: cumulative packet sizes reveal approximate message length.

#### 5.3.1. Keystroke timing attacks

[Song, Wagner, and Tian (2001)](/docs/doi-10.5555-1251327.1251352.pdf) demonstrated that inter-keystroke timing in encrypted SSH sessions leaks approximately 1 bit of information per keystroke pair. SSH in interactive mode sends each keystroke as a separate packet immediately after it is pressed, so packet timing directly mirrors typing rhythm. Using a Hidden Markov Model trained on typing patterns, their system could narrow password search spaces by a factor of 50.

RTT systems are susceptible to the same class of attack. Depending on the transmission approach, RTT may send updates per keystroke (3.1) or per edit (3.3), producing packet timing that mirrors the sender's typing rhythm in the same way.

#### 5.3.2. User identification via typing patterns

[Keystroke dynamics](https://en.wikipedia.org/wiki/Keystroke_dynamics) – the study of typing rhythm as a behavioral biometric – is a well-established research area. Typing patterns are influenced by factors like typing speed, hand size, keyboard familiarity, and habitual key sequences. Two commonly studied timing features are _dwell time_ (how long a key is held) and _flight time_ (the interval between releasing one key and pressing the next).

One approach to extracting a stable typing signature is to compute the frequency spectrum of inter-keystroke intervals via the Fast Fourier Transform. Dominant peaks in the spectrum may correspond to rhythmic constants in a person's typing, such as a base typing speed or characteristic inter-word pauses. If such a signature is consistent across sessions, an eavesdropper could potentially identify users across encrypted RTT conversations without decrypting any content.

### 5.4. Countermeasures

Several techniques can mitigate timing and traffic analysis:

**Batching at fixed intervals.** Rather than transmitting on each keystroke, updates are buffered and sent at a constant interval, destroying the inter-keystroke timing signal. XEP-0301 recommends 700ms intervals for interoperability; OpenSSH's `ObscureKeystrokeTiming` option uses 20ms intervals. The trade-off is added latency: the receiver sees updates in steps rather than character-by-character.

**Timing metadata in the encrypted payload.** If updates are batched, the original keystroke timestamps can be included inside the encrypted payload. The receiver then plays back the text with natural rhythm while the eavesdropper sees only uniform packet spacing. This preserves the real-time feel of RTT without leaking timing information on the wire.

**Padding.** Encrypting each update to a fixed-size packet obscures how much text each update contains. Without padding, packet size reveals whether the sender typed one character or ten. Padding eliminates this signal at the cost of bandwidth.

**Dummy traffic.** Sending packets at a constant rate even when the sender is idle prevents an eavesdropper from distinguishing typing from silence. This is the most expensive countermeasure but provides the strongest protection.

These countermeasures can be combined. For example, batching at fixed intervals with padded payloads and embedded timing metadata addresses the three main side channels (timing, size, and activity) while preserving the real-time experience for the recipient.
