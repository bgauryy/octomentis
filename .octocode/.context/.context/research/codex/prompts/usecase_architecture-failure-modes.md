# architecture-failure-modes

**Message ID:** `home.useCases.architectureFailureModes.prompt`
**Mode:** `local`

## Prompt

Explain the top failure modes of my application's architecture.

Approach:
- Derive the architecture from repo evidence (services, DBs, queues, network calls, critical paths).
- Identify realistic failure modes (availability, data loss, latency, scaling, consistency, security, dependency outages).

Output:
- 1 short overview paragraph.
- Then ≤5 bullets: Failure mode, Trigger, Symptoms, Detection, Mitigation.
- If key architecture details are missing, state what you inferred vs. what you confirmed.
