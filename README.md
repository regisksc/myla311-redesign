# MyLA311

A Flutter app for preparing Los Angeles service reports and reporting illegal dumping to MyLA311.

- `reports/`: native app, organized into app composition, shared design, Reports, Services, Account, Home and Dev/API features.
- `animation/`: the authored submission animation project.
- `design-prototype/`: interface references and artwork.

The [canonical v2 design](design-prototype/reports-prototype-buttons-v2.html)
extends the existing layout to all 68 advertised services. Start a Report opens
the service catalog; the gear opens Settings with account tools. Saved reports use contextual actions. There is no bottom navigation bar.
OpenDesign copies follow this repository file. The native app includes the
catalog, service information, guided previews, Settings, account demonstrations,
Help and saved reports. Other services and account access
remain local previews. Only illegal-dumping submissions use the City's live API.

The live illegal-dumping flow supports drafts, photos, map search, anonymous or
named contact, submission recovery and saved receipts. Its six steps are Location,
Items, Photos, Details, Contact and Review. Existing drafts retain their saved
progress, and clearing preview data preserves real submissions and receipts.
Other-service previews retain optional details, landmarks and follow preferences
and require explicit local-only confirmation before creating a receipt. Their
lookup IDs identify local previews, not City Service Requests. Services whose
access requirements are unverified show information without a new preview action.

Run Flutter commands from `reports/`.

Developer tools use the `REPORTS_DEV_MODE` build flag. It defaults to enabled in
debug builds and disabled in profile and release builds. Pass
`--dart-define=REPORTS_DEV_MODE=false` to hide them in debug, or
`--dart-define=REPORTS_DEV_MODE=true` to explicitly enable them in another build.
The HTML design preview hides its developer playground unless opened with
`?dev=1`.

Project guidance lives in [AGENTS.md](AGENTS.md) and the [glossary](GLOSSARY.md).
The project documentation records the implementation decisions
and implementation records. See the [agent workflow](docs/agents/issue-tracker.md)
for local issue tracking and the [Portal API reference](docs/portal-api.md)
for the submission contract.
