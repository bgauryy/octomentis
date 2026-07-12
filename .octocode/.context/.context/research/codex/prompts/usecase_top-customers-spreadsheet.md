# top-customers-spreadsheet

**Message ID:** `home.useCases.topCustomersSpreadsheet.prompt`
**Mode:** `local`

## Prompt

Query my database and create a $spreadsheet with my top 10 customers.

Requirements:
- Define “top” using the most reliable available metric (e.g., revenue, ARR, usage), and state which one you used.
- Include consistent columns (name, metric, period, segment, notes) and clear units.

Constraints:
- Do not guess missing values; leave blanks or mark as N/A.

Output:
- Generate the $spreadsheet and include the filename/path.
- Add a short note explaining the ranking logic and any data caveats.
