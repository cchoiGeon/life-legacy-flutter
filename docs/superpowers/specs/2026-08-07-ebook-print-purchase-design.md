# E2/E3 · PDF 공유 · 구매(FREE~T4) · 종이책 주문 stub

**Date:** 2026-08-07  
**Status:** Approved (개발진행)

## Decisions

| Topic | Choice |
|-------|--------|
| Product codes | Keep FREE + T1~T4 (not Digital/Premium rename) |
| Purchase UI | Card style like attached mock; web-only pay notice; bottom refund + FAQ |
| Book steps | Shared timeline on purchase list; plans show which steps they unlock |
| PDF share | E2 + E3 via system share sheet (`share_plus`) |
| Print order | Full UI + server stub API; no real payment |
| Approach | Extend existing `purchase_*` / `preview_*` / `guide_*` |

## Flows

### Purchase
1. List: FREE + T1~T4 selectable cards (FREE is informational / current free tier).
2. Shared section: 「책이 만들어지는 순서」 steps 1–4 (from attached guide).
3. Bottom: web payment notice, expandable refund policy, FAQ accordion (product guide).
4. Detail: features + which creation steps this plan covers → 「웹에서 구매」 / coupon.

### E2 / E3
- Keep page preview / complete UI.
- Add share: generate PDF → temp file → `Share.shareXFiles`.
- E3 「가족에게 보내기」 → same share.
- E3 「종이책으로 주문하기」 → print order flow.

### Print order (no payment)
1. Address (reuse shipping-address GET/PUT).
2. Options: quantity (default 4), note optional.
3. Summary: book title, address, qty, “결제는 웹에서 / 앱은 신청만”.
4. `POST /print-orders` stub → success screen.

### Guide
- Extend `GuideContent` with ebook PDF, share, print order, web purchase, creation timeline.

## Server stub

`POST /print-orders` body: `{ bookId, quantity, note? }` (address from saved shipping).  
Response: `{ id, status: 'requested', bookId, quantity, createdAt }`.  
Persist minimal row or in-memory acceptable for stub; prefer TypeORM entity if cheap.

## Out of scope
- Real PG / IAP payment
- Renaming plans to Digital/Premium
- Redesigning entire Figma A–F
