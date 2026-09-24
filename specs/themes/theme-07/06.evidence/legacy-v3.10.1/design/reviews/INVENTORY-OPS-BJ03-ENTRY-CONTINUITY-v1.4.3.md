# Product Review — Inventory Operations + BJ03 Entry Architecture & Journey Continuity v1.4.3

## Trigger

Product review of v1.4.2 found a deeper usability problem than card/layout polish: some screens were correct in isolation but confusing when considered as a real user journey. A user could ask:

- Why am I on this screen?
- Which feature/task brought me here?
- Is this my action or another actor's task?
- If the task is waiting, who owns the next step?
- Where does Back return?
- When source/approval changes, do I resume the same task or start again?

The root cause was that the prototype had been optimized around **UIF-local screen flows**, while Product navigation/actor continuity was not canonicalized at the same rigor.

## Correction model

A Product-ready screen must carry five pieces of continuity:

1. **Entry reason** — module, parent object, assigned task, actor handoff, in-flow state, recovery or result.
2. **Actor owner** — the current user must not silently become another actor.
3. **Parent context** — deep-link/contextual screens must retain the object that explains their existence.
4. **Safe Back/exit** — never back to a consumed commit or a parent that never existed.
5. **Re-entry identity** — waiting/source/approval updates resume the same business task/version chain where the contract says so.

The canonical entry classes are:

`MODULE_ENTRY · CONTEXTUAL_DEEP_LINK · CONTEXTUAL_ONLY · ACTOR_HANDOFF_TASK · IN_FLOW_SURFACE · SYSTEM_RECOVERY · RESULT`

## Product-level outcome by journey

### BJ01 — Tồn kho

- `SCR-001` stays a normal module entry.
- `SCR-003` now formally supports Product/inventory contextual deep-link and Back-to-source context.
- No business logic change.

### BJ02 — Nhận hàng mua

- Generic entry: `Inventory → Nhận hàng → SCR-006`.
- Known Purchase document entry: direct to document-mode `SCR-009`, avoiding redundant Document/Quick choice.
- Approval is a real actor handoff: maker stops at waiting; approver enters `SCR-011` from assigned work.
- `SCR-013` is recovery-only and cannot be discovered as a normal feature.

**Product effect:** the user no longer has to infer why an approval/recovery screen suddenly appeared or act as if maker and approver were one session.

### BJ03 — Xác nhận giá trị ban đầu

- Module meaning is presented as **Hàng chờ xác nhận giá nhập**.
- Receipt task can deep-link to `SCR-015` with receipt ownership visible.
- BJ02 creates downstream valuation work but does not auto-route warehouse actor into a financial task.
- Initial valuation vs BJ13 late-cost boundary is explicit.

**Product effect:** a financial actor can understand what the queue represents and why a receipt appears there without knowing the internal `VALUATION_PENDING` vocabulary.

### BJ04 — Giữ hàng theo đơn

- BJ04 is not a standalone Inventory feature.
- Canonical Product path: `Order detail → SCR-021 → Back to order`.
- Old SCR020/022/023/024 Product routes are retired.

**Product effect:** a read-only reservation projection no longer appears as a mysterious task with no action.

### BJ05 — Lấy hàng

- Module queue + assigned-order deep-link are both explicit.
- Assigned task Back returns to the picking queue/source context.

**Product effect:** the journey remains one of the clearest operational task models and now has formal entry/re-entry semantics.

### BJ06 — Hàng khách trả

- Maker queue/request and wrong-LOT approver work are independent sessions.
- Approver works on the immutable approval case, not by taking over maker navigation.
- Shared `SCR-035` is split by mental role in copy/state: receipt milestone vs terminal classification result.

**Product effect:** the user can distinguish “hàng đã được tiếp nhận nhưng còn phải phân loại” from “yêu cầu đã kết thúc”.

### BJ07 — Trả nhà cung cấp

- Queue-level context explains source ownership by Purchase without repeating long helper text on every card.
- Specific source-authorized task can open `SCR-037` directly.
- Mismatch/source delta explicitly changes waiting ownership to Purchase.
- New source version returns to the same preparation task; warehouse never gets a hidden commercial-edit role.

**Product effect:** the user knows both **why the task exists** and **what to do when it cannot continue**.

## Documentation and trace corrections

- `bj-ui-flow-map.md` and `navigation-areas.md` now reflect current Product topology, especially UIF04.
- `screen-registry.json/.md` carries current entry architecture metadata.
- `SCR-041` machine trace no longer contains obsolete UIF07 transition IDs T09/T10/T11.
- Historical Harness artifacts are explicitly marked historical where they could otherwise contradict current topology.

## QA gates added/promoted

### Journey discoverability

For each active Product surface QA asks:

- WHY_HERE
- ENTRY_CLASS
- ACTOR_OWNER
- PARENT_CONTEXT
- BACK_TARGET
- WAITING_OWNER
- REENTRY
- NO_GHOST_NAV

### Runtime direct-entry specimens

The review harness simulates module, contextual and actor-task entry through URL fixtures such as `?uif=UIF-02&entry=document-context`. These are **QA simulations**, not a replacement for application routing.

### Protected regression

All non-target UIF08–UIF17 flows are compared to parent v1.4.2 for exact READY-state rendered text/topology. This catches shared-screen leakage; during QA it exposed a stale generic SCR037 notice and that regression was corrected before release.

## Final evidence

- 43/43 entry static/contract checks PASS.
- 57/57 entry/journey runtime checks PASS.
- 73/73 semantic hierarchy checks PASS.
- 17/17 business invariant checks PASS.
- 87 registered screen renders PASS.
- 121/121 protected non-target regression checks PASS.
- 37/37 visual checks across 18 canonical 402×874 specimens PASS.

## Product status

v1.4.3 is a **Product-review candidate**. QA evidence proves contract/runtime/visual consistency for the defined cases; it does not substitute for Product approval or real app navigation integration.
