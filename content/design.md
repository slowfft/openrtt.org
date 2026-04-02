---
title: Designing a real-time text system
---

# Designing a real-time text system

## 1. A protocol for real-time text transmission

### 1.1. Considerations

When designing or choosing a protocol for transmission of real-time text, consider the following factors:

Transport protocol
: Will the real-time text protocol run over TCP or UDP or something else? TCP guarantees ordering and delivery of packets at the cost of performance whereas UDP is "fire and forget", eschewing reliability for speed.

Correctness and recoverability
: How does the protocol handle network connection interruptions and package loss? What are the requirements on correctness?

Bandwidth, performance and scalability
: Some real-time text protocols are more resource-demanding than others at the expense of reliability and ease of implementation. Consider hardware and bandwidth limitations as well as desired scale.

User interface
: How will real-time text messages be displayed to the recipients?

Protocol flexibility
: Can the protocol be modified and expanded to accommodate features like rich text, emojis, media attachments, replies, user tagging, and so on?

### 1.2. Techniques

Three basic techniques. Further elaboration needed.

#### 1.2.1. Transmit exact keystrokes

- Can optionally include cursor position
- Minimal and simple
- Can be made more efficient by batching input
- Message cannot be repaired if packets are lost

#### 1.2.2. Transmit entire message per keystroke

- Actions: _EditMessage_, _SendMessage_
- Redundant and expensive but robust due to being self-repairing

#### 1.2.3. Transmit a diff

- Actions: _EditMessage_, _SendMessage_
- Efficient but more complicated
- Message cannot be repaired if packets are lost

### 1.3. Real examples

- 1998: [ITU-T T.140: Protocol for multimedia application text conversation](https://www.itu.int/rec/T-REC-T.140/en)
  [[Mirror](/docs/T-REC-T.140-199802-I!!PDF-E.pdf)] [[Mirror of addendum](/docs/T-REC-T.140-200002-I!Add1!PDF-E.pdf)]
- 2005: [IETF RFC 4103: RTP Payload for Text Conversation](https://www.rfc-editor.org/rfc/rfc4103.txt) [[Mirror](/docs/rfc4103.txt)]
- 2008: [IETF RFC 5194: Framework for Real-Time Text over IP Using the Session Initiation Protocol (SIP)](https://www.rfc-editor.org/rfc/rfc5194.txt) [[Mirror](/docs/rfc5194.txt)]
- 2013: [XEP-0301: In-Band Real Time Text](https://xmpp.org/extensions/xep-0301.html) [[HTML mirror](/docs/xep-0301.mhtml)] [[PDF mirror](/docs/xep-0301.pdf)]

## 2. Encryption

Key establishment protocols are out of scope for this page. Assume that each participant in an encrypted real-time text channel has an asymmetric key pair or a symmetric key that will encrypt and decrypt bytes (for the sake of performance, a symmetric key is preferred). Then, either a block cipher or a stream cipher can be used.

Encryption alone may not be sufficient to ensure secrecy, as the real-time text format makes communication especially susceptible to [timing attacks](https://en.wikipedia.org/wiki/Timing_attack) via typing pattern analysis. It is possible that such analysis can be countered by introducing by batching sender input and including timing metadata in the encrypted payload so that recipients can play messages back with correct timing. Further research is needed.

## 3. Associating message updates to users and existing messages

Some real-time text protocols might include minimal metadata in message packets in order to save bandwidth and might only include comprehensive metadata at the start or end of messages. For example, data such as sender ID and attachment data may be omitted in all EditMessage updates except the one that initiated a message.

## 4. User interface

TODO.

## 5. Platform – web, native, mobile

Different platforms provide different advantages and disadvantages.

- TODO: encryption.
  - Browser cryptography considered insecure
- TODO: user interface.
  - Desktop: easier typing (debatable considering modern habits)
  - Desktop: easier reading in crowded chats
  - Mobile: for push notifications
