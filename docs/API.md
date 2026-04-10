# API Documentation

## Endpoints
### Case Intake
- **Description**: Collect, validate and normalize customer profiles from Sanctions Lists; attach a runId and timestamp for traceability.
- **Type**: Processing

### Reason
- **Description**: Execute reason phase for the Chain-of-Thought pattern: persist interim state, enforce guardrails, and emit structured JSON results.
- **Type**: Processing

### Decide
- **Description**: Execute decide phase for the Chain-of-Thought pattern: persist interim state, enforce guardrails, and emit structured JSON results.
- **Type**: Processing

### Break Resolution
- **Description**: Break Resolution across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
- **Type**: Processing

### Case Management
- **Description**: Case Management across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
- **Type**: Processing

### Risk Scoring
- **Description**: Risk Scoring across joined datasets; branch on thresholds using decision gates; write metrics (success/error counts) for observability.
- **Type**: Processing

### Operations Handoff
- **Description**: Assemble final payload with status, artifacts, KPIs and audit trail; store to SWIFT Gateway; return response JSON for the client.
- **Type**: Processing
