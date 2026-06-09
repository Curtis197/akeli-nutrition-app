# Local Testing Workflow

Use this workflow to implement robust, test-driven logic in the Akeli app. This workflow ensures that absolutely no code is deployed without automated verification.

> [!IMPORTANT]
> **Execute Without Asking:** When executing this workflow, you must run the testing commands automatically via the terminal. Do not stop to ask the user for permission to run `deno test`, `supabase test db`, or `flutter test`.

## Step 1: Identify the Domain
Determine where the logic resides:
- **Dart:** `test/` (Flutter unit/widget tests)
- **Edge Function:** `supabase/functions/<name>/index.test.ts` (Deno tests)
- **Database (RPC/Trigger):** `supabase/tests/database/<name>.test.sql` (pgTAP tests)

## Step 2: Scaffold the Test First (TDD)
Before writing the final implementation, create the test file. 
- Define the "happy path" (successful execution).
- Define edge cases (missing data, malformed data).
- Define permission/RLS constraints.

## Step 3: Implement the Logic
Write the actual function, RPC, or Dart class to satisfy the requirements.

## Step 4: Execute the Tests Automatically
Run the appropriate test command using your terminal tool:
- Dart: `flutter test test/<path>`
- Edge Function: `cd supabase/functions/<name> && deno test -A index.test.ts`
- Database: `supabase test db`

## Step 5: Iterative Fixing
If the tests fail, read the error output carefully. 
Modify the implementation or the test as necessary and **run the test again**. Continue this loop until 0 errors are reached.

## Step 6: Final Reporting
Once all tests pass, report the success to the user and present a summary of what was covered by the tests.
