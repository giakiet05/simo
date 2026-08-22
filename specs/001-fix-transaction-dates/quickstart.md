# Quickstart & Verification Guide: Transaction Dates & Timestamps

## Overview
This guide provides manual and automated verification scenarios to prove that transaction date retention on edit, 3-tier timestamp display, and transaction sorting work properly end-to-end.

---

## Test Scenario 1: Preserving Transaction Date on Edit
1. Open the application.
2. Select or create a transaction with a past date (e.g., March 15).
3. Tap on the transaction to open the Action / Edit menu.
4. Open the Edit Form.
5. Verify that the date selector displays **March 15** (not today's date).
6. Edit the amount or note, and save the transaction.
7. Return to the transaction list.
8. **Expected Result**: The transaction is still listed under **March**, retaining March 15 as its transaction date.

---

## Test Scenario 2: 3-Tier Timestamps Visibility
1. Open a transaction's action menu / details sheet.
2. Verify the presence and order of the 3 timestamp entries:
   - **Ngày giao dịch**: e.g., 15/03/2026
   - **Ngày tạo**: e.g., 20/07/2026 14:30
   - **Ngày cập nhật**: e.g., 20/08/2026 09:15
3. **Expected Result**: All 3 dates/times are accurately shown in the exact specified order.

---

## Test Scenario 3: Sorting by Transaction Date
1. Create Transaction A with Transaction Date = March 1, 2026 (created today).
2. Create Transaction B with Transaction Date = May 1, 2026 (created yesterday).
3. View the Transaction Screen.
4. **Expected Result**: Transaction B appears above Transaction A because its Transaction Date is newer (May > March), despite their creation timestamps.
