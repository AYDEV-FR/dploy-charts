{{/*
Port plumbing shared by service.yaml, extra-services.yaml, deployment.yaml and
networkpolicy.yaml.

A stack published by docker compose can expose several ports, and they rarely
want the same treatment: an HTTP port sits on a ClusterIP behind the gateway,
while a raw TCP port needs its own LoadBalancer with its own external-dns
annotation. One Service cannot express that (a Service has a single `type`), so
the chart renders one primary Service plus any number of extra ones.
*/}}

{{/*
Primary Service ports, normalized to {name, port, targetPort, protocol}.
Falls back to the legacy single `service.port` so existing releases keep working.
*/}}
{{- define "compose.primaryPorts" -}}
{{- if .Values.service.ports }}
{{- range .Values.service.ports }}
- name: {{ .name | default "entry" | trunc 15 | trimSuffix "-" }}
  port: {{ .port }}
  targetPort: {{ .targetPort | default .port }}
  protocol: {{ .protocol | default "TCP" }}
{{- end }}
{{- else }}
- name: entry
  port: {{ .Values.service.port }}
  targetPort: {{ .Values.service.port }}
  protocol: TCP
{{- end }}
{{- end -}}

{{/*
Every port the pod must declare a containerPort for, deduplicated by port
number: the primary Service's targets plus every extra Service's targets.
Names are what the Service `targetPort` references, so they must match.
*/}}
{{- define "compose.containerPorts" -}}
{{- $seen := dict -}}
{{- range (include "compose.primaryPorts" . | fromYamlArray) }}
{{- $p := .targetPort | toString }}
{{- if not (hasKey $seen $p) }}
{{- $_ := set $seen $p .name }}
- name: {{ .name }}
  containerPort: {{ .targetPort }}
  protocol: {{ .protocol }}
{{- end }}
{{- end }}
{{- range $svc := .Values.extraServices }}
{{- range $svc.ports }}
{{- $p := (.targetPort | default .port) | toString }}
{{- if not (hasKey $seen $p) }}
{{- $_ := set $seen $p (.name | trunc 15 | trimSuffix "-") }}
- name: {{ .name | trunc 15 | trimSuffix "-" }}
  containerPort: {{ .targetPort | default .port }}
  protocol: {{ .protocol | default "TCP" }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
The port probes and the HTTPRoute/Ingress backend point at: `service.probePort`
when set, otherwise the first primary port. A multi-port stack whose first port
is not the one that signals readiness should set probePort explicitly.
*/}}
{{- define "compose.primaryPort" -}}
{{- if .Values.service.probePort -}}
{{- .Values.service.probePort -}}
{{- else -}}
{{- (first (include "compose.primaryPorts" . | fromYamlArray)).port -}}
{{- end -}}
{{- end -}}

{{/*
Ports reachable from OUTSIDE the cluster — a LoadBalancer Service is hit
directly by players, so the traffic has no source namespace for a
namespaceSelector to match. Opt in per Service with `externalIngress: true`.
*/}}
{{- define "compose.externalPorts" -}}
{{- if .Values.service.externalIngress }}
{{- range (include "compose.primaryPorts" . | fromYamlArray) }}
- protocol: {{ .protocol }}
  port: {{ .targetPort }}
{{- end }}
{{- end }}
{{- range $svc := .Values.extraServices }}
{{- if $svc.externalIngress }}
{{- range $svc.ports }}
- protocol: {{ .protocol | default "TCP" }}
  port: {{ .targetPort | default .port }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
