# Demo script

The acceptance checklist from SRS section 11. Run it top to bottom after
**Platform admin > Demo controls > Reset demo data**. Each step passes when the expected
result is seen. Password for every account: `demo1234`.

| # | Action | Expected result |
| --- | --- | --- |
| 1 | Pick ZUT, quick sign-in as student | Home shows recommendations with reasons, active loans and today's sessions |
| 2 | Search "ICT 2201", filter year 2023 | Matching paper listed; details show summary and available copies |
| 3 | Open the paper | PDF opens within 2 seconds |
| 4 | Tap **Request copy** | Loan appears in Loans as Requested |
| 5 | Sign in as ZUT librarian, approve the request in Request queue | Loan Approved; student sees a QR code and a notification |
| 6 | Librarian: Scan code, scan the student's QR (or type the six-character code) | Loan Collected; due date 7 days ahead |
| 7 | Scan the same code again | Error: code already used |
| 8 | Platform admin: Demo controls, +7 days then +1 day | Loan Overdue; student gets an overdue notification; new requests refused |
| 9 | Student: Study, Practice quiz, ICT 2201, 5 questions | Feedback after each question; results with topic breakdown |
| 10 | Open Revision plan and Progress | Dated sessions per course; chart includes the new attempt |
| 11 | Librarian: Papers, add a paper with course left empty | Save blocked with a field error |
| 12 | Complete the details and save | Paper searchable; enrolled students get a "new paper" notification |
| 13 | Sign in as Northbridge student, search "ICT 2201" | No results; only Northbridge courses visible |
| 14 | Sign in as ZUT admin, open Dashboard | Counts reflect today's actions; unmet searches listed |
| 15 | Platform admin: Institutions | Both tenants listed with totals and no student names |

## Tips

- Steps 6 and 7 need the Android phone's camera for a real scan. The typed code goes
  through the same service call, so it is a fair fallback on the emulator.
- After step 8, reset the clock before continuing if you want fresh due dates.
- The short inactivity timeout (5 minutes) is a toggle in Demo controls.
