# AGENTS.md

This file tells Codex how to operate in the SocialPredict repository. It is intentionally thin. Put detailed domain playbooks in specialized agents and skills, not here.

## 0. Operating mode

- You are an automated coding agent, not a human pair-programming partner.
- Do not stop to ask clarifying questions when a reasonable, conservative interpretation exists.
- Do not ask the user to confirm an approach before coding.
- Make the smallest repo-consistent change that fully addresses the task.
- State assumptions briefly in the final summary instead of blocking on them.
- If a task is partly blocked by a missing secret, unavailable external system, or absent file, complete all unblocked work and report the exact blocker.

## 1. Instruction precedence

Use this precedence order when deciding how to code:

1. The direct user request for the current task.
2. This `AGENTS.md` file.
3. SocialPredict repository conventions and README guidance.
4. The existing patterns already present in the touched package.

## 2. Delegation rule

- For multi-step, cross-cutting, or ambiguous backend work, start with `dispatcher-agent`.
- Prefer delegating specialized work instead of making the top-level agent improvise every concern itself.
- Specialists own their domain:
  - `architecture-agent`
  - `go-style-agent`
  - `coding-best-practices-agent`
  - `openapi-contract-agent`
  - `db-migration-agent`
  - `test-reliability-agent`
  - `verifier-agent`
- Let delegated specialists decide whether and how to use their relevant skills.
- Do not bypass a specialist just to run one of its scripts directly unless the task is explicitly about that script.
- Defer general Go style interpretation to `go-style-agent`.

## 3. SocialPredict backend invariants

Preserve these repo-level rules unless the task explicitly requires changing them:

- In this repo, a handler means an actual HTTP handler at the request boundary.
- Keep reusable core logic out of `http.ResponseWriter` and `*http.Request` code when practical.
- Acquire `*gorm.DB` once near the handler boundary and pass it downward.
- Use transactions when multiple writes must succeed or fail together.
- Preserve public versus private model boundaries in API responses.
- Preserve integer-first accounting and market-economics behavior.
- Keep time-based enforcement on the server side.
- Use higher-order function injection selectively for real dependencies such as setup or economics loaders.
- Preserve existing 32-bit safety guards when converting `uint64` to platform-sized `uint`.
- Never log secrets, passwords, tokens, or API keys.

## 4. Validation ownership

- Let `dispatcher-agent` choose the smallest useful specialist set for the task.
- Use `verifier-agent` near the end for final validation and diff sanity checks.
- Do not hardcode a single validation command sequence here; validation should match the change.

## 5. Final response

When the task is complete, write a concise plain-text run summary that can be
written directly to a summary file or last-message artifact. Summarize briefly:

- what changed
- what assumptions were made
- what checks were run
- any blocker or follow-up that remains

Do not end by asking for confirmation if the requested work is already reasonably complete.
