# Architecture Documentation

## Overview
This Chain-of-Thought implements Reconciliation Engine • Collateral (Corporate Banking) for Banking & Finance use cases.

## Components
1. **Case Intake**: Collect, validate and normalize customer profiles from Sanctions Lists; attach a runId and timestamp for traceability.
2. **Reason**: Execute reason phase for the Chain-of-Thought pattern: persist interim state, enforce guardrails, and emit structured JSON results.
3. **Decide**: Execute decide phase for the Chain-of-Thought pattern: persist interim state, enforce guardrails, and emit structured JSON results.
4. **Break Resolution**: Break Resolution across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
5. **Case Management**: Case Management across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
6. **Risk Scoring**: Risk Scoring across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
7. **Operations Handoff**: Assemble final payload with status, artifacts, KPIs and audit trail; store to SWIFT Gateway; return response JSON for the client.

## Data Flow
- Input: Case Intake
- Processing: 7 sequential steps
- Output: Operations Handoff
