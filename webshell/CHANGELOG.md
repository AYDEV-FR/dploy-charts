# Changelog

All notable changes to the webshell Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-30

### Added

- Gateway API `HTTPRoute` template, opt-in via `httpRoute.enabled`, as an
  alternative to `Ingress` for clusters running the Gateway API (e.g. Cilium
  agentgateway). Routes `/` to the chart's service; configurable
  `parentRefs`, `hostnames` and `annotations`. May coexist with
  `ingress.enabled`, but typically only one is enabled per deployment.

## [1.0.0] - 2025-12-19

### Breaking Changes

**Values structure changes:**
- Moved `livenessProbe` and `readinessProbe` from root level to `container.livenessProbe` and `container.readinessProbe`
- Moved tty2web resources from `ingress.tty2web.resources` to `tty2web.resources`
- Removed incorrect sections under `ingress` (lines 98-106 in old values.yaml)
- Changed `serviceAccount.automount` default from `true` to `false` for improved security

**Template changes:**
- Fixed critical syntax error in `service.yaml` (removed spaces in template delimiters)
- NetworkPolicy now uses templated name `{{ fullname }}-deny-all` instead of hard-coded `deny-all`
- Renamed template file: `statefulset-container.yaml` → `statefulset.yaml`
- Service selector now varies based on deployment mode

**Chart metadata:**
- Bumped version from 0.1.0 to 1.0.0
- Enhanced Chart.yaml with keywords, kubeVersion, home, and sources

### Added

**New features:**
- Schema validation (`values.schema.json`) to validate configuration
- Helm tests (`templates/tests/test-connection.yaml`) for automated testing
- Post-installation notes (`NOTES.txt`) with access instructions
- Deployment mode support: choose between `deployment` (separate pod) or `sidecar` (same pod)
- Configurable replica count via `replicaCount` value
- Configurable NetworkPolicy via `networkPolicy.enabled`
- Configurable RBAC via `rbac.create`
- Persistence toggle via `persistence.enabled`

**New configuration options:**
- `tty2web.enabled` - Enable/disable tty2web component
- `tty2web.deploymentMode` - Choose deployment mode: `deployment` or `sidecar`
- `tty2web.securityContext` - Security context for tty2web container
- `networkPolicy.enabled` - Enable/disable NetworkPolicy
- `networkPolicy.policyType` - Network policy type
- `rbac.create` - Enable/disable RBAC resource creation
- `persistence.enabled` - Enable/disable persistent storage

**Security enhancements:**
- Added `tty2web.securityContext` with restrictive defaults
- Added `podSecurityContext` defaults (fsGroup: 1000, seccompProfile: RuntimeDefault)
- Changed service account automount default to `false`

**Documentation:**
- Comprehensive README.md with architecture, configuration, and troubleshooting
- CHANGELOG.md for version tracking
- Enhanced Chart.yaml metadata

**Template improvements:**
- New helper functions in `_helpers.tpl`:
  - `webshell.networkpolicy.name` - Templated NetworkPolicy name
  - `webshell.pod.name` - StatefulSet pod name
  - `webshell.tty2web.selectorLabels` - tty2web component labels
  - `webshell.container.selectorLabels` - Container component labels
  - `webshell.validateValues` - Configuration validation
- Separate `networkpolicy.yaml` template (extracted from StatefulSet)
- Component-specific selector labels for better organization

### Fixed

**Critical fixes:**
- Fixed syntax error in `service.yaml` where template delimiters had spaces (`{ {` → `{{`)
- Fixed NetworkPolicy namespace collision by using templated name
- Fixed hard-coded replicas in StatefulSet and Deployment
- Fixed hard-coded pod name in tty2web args and RBAC resources
- Fixed naming inconsistency in `ingress.yaml` (`cloudshell` → `webshell`)
- Fixed comment in values.yaml (line 1: `cloudshell` → `webshell`)

**Values structure fixes:**
- Fixed probe path mismatch (templates expected `container.livenessProbe` but values had them at root)
- Fixed resource path mismatch (templates expected `tty2web.resources` but values had it under `ingress.tty2web`)
- Removed confusing and unused sections from values.yaml

### Changed

**Structural improvements:**
- Reorganized values.yaml for better clarity and logical grouping
- NetworkPolicy extracted to separate template file
- Improved template organization and consistency
- Updated Chart description to be more descriptive

**Behavioral changes:**
- RBAC resources now only created when `rbac.create=true` AND `deploymentMode=deployment`
- Service selector now conditional based on deployment mode
- Validation now enforces `replicaCount=1` when using deployment mode

### Migration Guide

For users upgrading from version 0.1.0:

1. **Backup your current configuration:**
   ```sh
   helm get values my-webshell > values-backup.yaml
   ```

2. **Update your values.yaml structure:**

   **Before (0.1.0):**
   ```yaml
   livenessProbe:
     httpGet:
       path: /

   ingress:
     tty2web:
       resources:
         requests:
           cpu: "64m"
   ```

   **After (1.0.0):**
   ```yaml
   container:
     livenessProbe:
       httpGet:
         path: /

   tty2web:
     resources:
       requests:
         cpu: "64m"
   ```

3. **Add new required sections:**
   ```yaml
   replicaCount: 1

   tty2web:
     enabled: true
     deploymentMode: "deployment"  # or "sidecar"
     securityContext:
       capabilities:
         drop: [ALL]
       allowPrivilegeEscalation: false
       runAsNonRoot: true
       runAsUser: 1000
       readOnlyRootFilesystem: true

   networkPolicy:
     enabled: true
     policyType: "deny-all"

   rbac:
     create: true

   persistence:
     enabled: true
   ```

4. **Test in non-production first:**
   ```sh
   helm upgrade my-webshell ./webshell --dry-run --debug
   ```

5. **Perform the upgrade:**
   ```sh
   helm upgrade my-webshell ./webshell
   ```

### Known Limitations

- Replica count is limited to 1 when using deployment mode
- Sidecar mode implementation is planned for future release
- Custom NetworkPolicy rules not yet supported (only deny-all)

## [0.1.0] - Earlier

Initial release with basic functionality:
- StatefulSet for container workload
- Deployment for tty2web
- NetworkPolicy with deny-all rules
- RBAC for kubectl exec
- Persistent storage
- Service and optional Ingress
