# Residual-risk Register

| ID | Class | Evidence gap | Impact | Owner | Unblock action | Target gate |
|---|---|---|---|---|---|---|
| HR-01 | Repository | No real handler/DB adapter | Cannot prove transaction/finality behavior | Engineering Lead | Implement mappings and execute catalog | G14 |
| HR-02 | Recovery | No crash/restart/outbox evidence | UNKNOWN and atomicity remain unproven at runtime | QA + Platform | Run P0 failure injection with immutable logs | G14/P0 |
| HR-03 | External integration | Broker retention/replay/SLO not exercised | Event recovery may violate operational targets | Platform Lead | Configure broker adapter and run replay/SLO suite | Integration |
| HR-04 | Deferred receiver | Outbound remains in Theme 7 | Temporary duplication persists | Business Owner + Theme 2/5/10 | Receiver accept/re-ID in later release | Receiver adoption |
| HR-05 | Deferred policy | D17 not adopted by Theme 2 | Pricing heuristic is not effective | Theme 2 Product Owner | Decide and freeze D17 in Theme 2 | Receiver policy |
