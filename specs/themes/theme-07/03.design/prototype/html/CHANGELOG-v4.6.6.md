# CHANGELOG — v4.6.6

## Scope

Role simulation for the `Theo BJ / UIF` review tab in the HTML prototype.

## Changed

- Added a workbench-only `Mô phỏng vai trò` controller to `Theo BJ / UIF`.
- Role choices are derived directly from the existing `actors` metadata of Screen Contracts in the active UIF.
- Selecting a role keeps the current screen when that actor is valid; otherwise the workbench prefers the first existing screen owned only by that actor; if none exists, it uses the first screen in the same UIF that already declares that actor.
- Screen navigation remains complete and visually distinguishes screens that belong to the selected review role.
- Inspector shows the simulated role, current-screen actors and `Screen Contract · actors` as the source.

## Not changed

- No actor, permission, approval-separation rule, CTA, state transition or mutation was added or modified.
- No BJ, UC, UIF, Screen Contract, PAT-NAV or PAT-UI-UX semantics were changed.
- The v4.6.5 Hub role profiles remain unchanged.
