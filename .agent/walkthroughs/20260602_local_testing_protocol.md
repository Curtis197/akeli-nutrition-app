# Local Testing Protocol Implemented

I have successfully scaffolded the complete local testing protocol according to your requirements. All automated agents and developers will now follow a strict testing cycle before deploying new code.

## 1. The Skill (`akeli-local-testing-protocol`)
Created at: `.agent/skills/akeli-local-testing-protocol/SKILL.md`

This skill defines the frameworks and execution commands for the three core environments:
- **Database / RPCs:** Enforces `pgTAP` usage via `supabase test db`.
- **Edge Functions:** Enforces `Deno.test` with tests placed directly next to the function logic (`index.test.ts`).
- **Dart / Flutter:** Enforces `flutter test` utilizing `mocktail` to avoid live backend calls during UI/Provider testing.

> [!CAUTION]
> The skill explicitly includes the **Zero Permission Rule**. The AI will now automatically execute tests via the terminal whenever logic is updated. It will iteratively read the error outputs and fix its own code until 0 errors remain.

## 2. The Workflow (`local-testing-workflow`)
Created at: `.agent/workflows/local-testing-workflow.md`

This workflow defines the step-by-step TDD process:
1. Identify the domain (Dart, Edge Function, DB).
2. Scaffold the test first, identifying happy paths and edge cases.
3. Implement the logic.
4. Execute tests locally and automatically.
5. Fix errors iteratively until all tests pass.

## 3. Project Guidelines Updated
I appended **Section 7: Automated Testing Requirements** directly into `GEMINI.md`. Because `GEMINI.md` is loaded into the context at the start of every session, this ensures the testing protocols will permanently govern how logic is built going forward.
