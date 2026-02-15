# Settle OS v1 Release Hardening

Updated: 2026-02-13

## Kill Switches (Staged Rollout)
- Provider: `lib/providers/release_rollout_provider.dart`
- Controlled modules:
  - Help Now
  - Sleep Tonight
  - Plan & Progress
  - Family Rules
  - Release Metrics screen
  - Safety & Compliance screen
- Home keeps exactly 4 destinations and soft-disables paused modules.

## Metrics Dashboard Wiring
- Screen: `lib/screens/release_metrics.dart`
- Service: `lib/services/release_metrics_service.dart`
- Sources: centralized `EventBusService` events only
- KPI coverage:
  - Help Now median time-to-output (target `<10s`)
  - Sleep Tonight median time-to-start (target `<60s`)
  - Help Now outcome-record rate
  - Sleep morning-review completion rate
  - 7-day repeat-use signal (active days with Help Now/Sleep Tonight)
  - Family Rules accepted diffs in last 7 days

## Release Ops Checklist
- Screen: `lib/screens/release_ops_checklist.dart`
- Service: `lib/services/release_ops_service.dart`
- Required gates for rollout-ready:
  - Help Now median latency `<10s`
  - Sleep Tonight median start `<60s`
  - Compliance controls mapped and passing
- Advisory signals:
  - Help Now outcome logging
  - Sleep morning review capture
  - 7-day repeat use
  - Family Rules accepted diffs

## Safety & Liability Surfaces
- Screen: `lib/screens/release_compliance_checklist.dart`
- Service: `lib/services/safety_compliance_service.dart`
- Registry-backed checks:
  - Behavioral-not-medical boundary
  - Red-flag redirects
  - Feeding physiological exclusions
  - Privacy/regulatory mappings (COPPA, breach notification, HIPAA boundary)

## Residual Release Gates
- Regulatory and clinical review status remains tracked in evidence registries.
- Production release requires legal/clinical sign-off on any `review_required` item.
