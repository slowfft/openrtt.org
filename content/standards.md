---
title: Standards and protocols for real-time text
---

# Standards and protocols for real-time text

Many implementations of real-time text systems exist only as proprietary or undocumented code. For a survey of real-time text systems, please refer to [_A survey of real-time text systems_](/software).

_WM: Archived via the Internet Archive Wayback Machine_

## Table of Contents

{{% toc %}}

## 1. T.140-based RTT over RTP/SIP

This family of standards forms a keystroke streaming approach to real-time text. T.140 defines the core text format and semantics, RFC 4103 provides the RTP transport with redundancy, and RFC 5194 supplies the SIP-based session framework.

### 1.1. ITU-T T.140 (1998)

T.140 _(Protocol for multimedia application text conversation)_ defines a foundational protocol for real-time text conversation in multimedia applications. Each character (or character group) is sent immediately as typed. Editing is supported via embedded control codes (e.g., backspace, delete, and cursor positioning). T.140 is transport-agnostic and focuses purely on text semantics and character-level streaming.

**Source**: [itu.int/rec/T-REC-T.140/en](https://www.itu.int/rec/T-REC-T.140/en)  
**Mirrors**: [[PDF](/docs/T-REC-T.140-199802-I!!PDF-E.pdf)] [[PDF of addendum](/docs/T-REC-T.140-200002-I!Add1!PDF-E.pdf)]

### 1.2. IETF RFC 4103 (2005)

RFC 4103 _(RTP Payload for Text Conversation)_ defines an RTP payload format that carries T.140 text over IP networks. Each RTP packet contains one T.140 block. UDP packet loss is mitigated by adding redundancy (RFC 2198), typically including up to two previous text generations in every packet. Timestamps and sequence numbers allow synchronization and loss detection.

**Source**: [rfc-editor.org/rfc/rfc4103.txt](https://www.rfc-editor.org/rfc/rfc4103.txt)  
**Mirrors**: [[TXT](/docs/rfc4103.txt)]

### 1.3. IETF RFC 5194 (2008)

RFC 5194 _(Framework for Real-Time Text over IP Using the Session Initiation Protocol (SIP))_ provides the architectural framework (Text-over-IP or ToIP) for deploying real-time text in SIP-based multimedia sessions. It defines session setup, SDP negotiation for the "text" media type, mid-call modality switching, and integration with other media (voice/video). It relies on T.140 encoding carried via RFC 4103 RTP payloads, with requirements for low latency (≤300 ms per character) and support for interworking with legacy TTY systems.

**Source**: [rfc-editor.org/rfc/rfc5194.txt](https://www.rfc-editor.org/rfc/rfc5194.txt)  
**Mirrors**: [[TXT](/docs/rfc5194.txt)]

## 2. XEP-0301: In-Band Real Time Text (2013)

XEP-0301 defines an in-band Real-Time Text protocol for XMPP. Unlike the T.140 family’s keystroke-streaming model, it uses a diff-based approach: updates are sent as XML action elements inside `<message/>` stanzas – `<t/>` for insertions at a position, `<e/>` for erasures, and `<w/>` for timing waits to preserve natural typing rhythm. Updates are typically sent every ~700 ms. A periodic `<rtt event='reset'/>` retransmits the full current state for synchronization. This design is more bandwidth-efficient, supports complex mid-message edits, and reduces the impact of packet loss compared to pure keystroke transmission.

**Source**: [xmpp.org/extensions/xep-0301.html](https://xmpp.org/extensions/xep-0301.html)  
**Mirrors**: [[WM](https://web.archive.org/web/20260402190312/https://xmpp.org/extensions/xep-0301.html)] [[PDF](/docs/xep-0301.pdf)] [[MHTML](/docs/xep-0301.mhtml)]
