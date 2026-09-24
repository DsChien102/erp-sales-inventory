# BJ05 + BJ06 UX QA — v2.8.2

**Result: PASS · 32/32**

- PASS — SCR027 renders one canonical Navigation row per LOT: 2
- PASS — SCR027 LOT rows share exact 76px geometry: [76, 76]
- PASS — SCR027 main overview has no inline quantity field: 
- PASS — SCR027 LOT rows expose required and picked quantity without prose blocks: 
- PASS — LOT editor uses canonical VBottomSheet: 
- PASS — LOT editor has canonical 48x4 handle: 
- PASS — LOT editor has no close X: 
- PASS — LOT editor exposes one quantity field, not duplicate LOT forms: 
- PASS — LOT editor content-hugs and does not become near-full-screen: 348
- PASS — Updating one LOT returns to compact overview: 
- PASS — Many-LOT stress remains one 76px row per allocation: {'count': 8, 'heights': [76, 76, 76, 76, 76, 76, 76, 76], 'fields': 0, 'overflow': 0, 'scrollable': True}
- PASS — Many-LOT stress does not multiply inline fields: {'count': 8, 'heights': [76, 76, 76, 76, 76, 76, 76, 76], 'fields': 0, 'overflow': 0, 'scrollable': True}
- PASS — Many-LOT stress uses natural vertical scroll with no horizontal overflow: {'count': 8, 'heights': [76, 76, 76, 76, 76, 76, 76, 76], 'fields': 0, 'overflow': 0, 'scrollable': True}
- PASS — Cần phân loại enters SCR033 directly: SCR-033
- PASS — SCR033 uses compact request context instead of three-row metadata block: 
- PASS — Classification editor is canonical VBottomSheet: 
- PASS — Classification editor uses one progress row and four fields: 
- PASS — Classification fields avoid repeated helper copy: 
- PASS — Classification sheet remains compact enough for one viewport: 646
- PASS — Back from classification returns maker queue: SCR-030
- PASS — Back from classification never enters approver SCR034: 
- PASS — Receipt request enters SCR031: 
- PASS — SCR031 uses compact request context: 
- PASS — Receipt line enters SCR032: 
- PASS — Back SCR032 returns owning SCR031: 
- PASS — Back SCR031 returns SCR030: 
- PASS — UIF06 review catalog keeps maker route before independent approver: ['SCR-030', 'SCR-031', 'SCR-032', 'SCR-033', 'SCR-035', 'SCR-034']
- PASS — SCR031 has at most one footer primary action: ['Ghi nhận hàng trả']
- PASS — SCR033 has one footer completion action: ['Hoàn tất phân loại']
- PASS — SCR035 intermediate retains explicit classify-now and defer choices: ['Để sau', 'Phân loại ngay']
- PASS — All BJ06 representative screens stay 402x874 with no app-content horizontal overflow: [{'sid': 'SCR-030', 'app': [402, 874], 'overflow': 0, 'bodyOverflow': 16}, {'sid': 'SCR-031', 'app': [402, 874], 'overflow': 0, 'bodyOverflow': 0}, {'sid': 'SCR-032', 'app': [402, 874], 'overflow': 0, 'bodyOverflow': 0}, {'sid': 'SCR-033', 'app': [402, 874], 'overflow': 0, 'bodyOverflow': 0}, {'sid': 'SCR-034', 'app': [402, 874], 'overflow': 0, 'bodyOverflow': 0}, {'sid': 'SCR-035', 'app': [402, 874], 'overflow': 0, 'bodyOverflow': 0}]
- PASS — No browser errors: []
