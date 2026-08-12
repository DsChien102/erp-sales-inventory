# BJ01 Key-value Row Alignment Correction — v2.4.5

**Parent:** v2.4.4  
**Authority:** live Figma DS v2.0.3 + BJ01 Product contracts  
**Business behavior:** unchanged

## Correction

The alignment fix must not introduce an independent typography rule. BJ01 continues to use `DS v2 / Key-value Row` (`525:358`) exactly as defined by Figma:

- `State=Default`: label = Inter 13/20 Regular; value = JetBrains Mono 14/22 Regular.
- `State=Emphasis`: label = Inter 14/20 Semi Bold; value = Inter 16/22 Semi Bold.
- Both label and value are non-shrinking text items (`shrink-0` semantics).
- Row geometry stays 338x44; supporting rows share a stable right edge.

## Rule lock

Typography is component/variant-owned. Numeric content alone does not select JetBrains Mono. Do not override the component simply because a string contains numbers.
