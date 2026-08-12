# Changelog — Theme 7 Prototype Harness v3.6.1

Parent: **v3.6.0**  
Date: **2026-09-15**

## Sticky Footer dual-action correction

- Fixes the footer defect reported on the inventory-count session: when a footer has two CTAs they are now rendered on **one horizontal row**, never stacked vertically.
- Applies the correction at the shared Sticky Footer layer, not only to the reported screen.
- Canonical Dual layout: **402×92**, horizontal content padding **16**, top **12**, bottom **24**, **8** gap, two **181×44** actions.
- Action order is normalized to **Secondary/Destructive | Primary**.
- Destructive secondary actions keep danger semantics while the primary completion action remains primary.
- Single-action footers are unchanged.

## QA expansion

- Baseline audit found **17** two-action footer route-state occurrences; **11** were vertically stacked before the correction.
- Post-fix footer audit: **17/17** dual-footer states horizontal, exact geometry, correct action order, no viewport/footer bleed, no 3+ action footer, and **271** single-primary footer occurrences unchanged.
- Full regression remains green: runtime UI **14/14**, semantic flow logic **21/21**, full-theme completion **14/14**, representative coherence **8/8**, all-flow runtime smoke **89/89**, device-frame QA **7/7**, with **0 browser page errors**.

## Scope lock

- UI-only correction.
- No business rule, field, permission, state, action, transition or navigation change.
- No new Design System component.
