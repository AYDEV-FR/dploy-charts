{{/*
Expand the name of the chart.
*/}}
{{- define "web-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "web-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "web-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "web-app.labels" -}}
helm.sh/chart: {{ include "web-app.chart" . }}
{{ include "web-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "web-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "web-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "web-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "web-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Render a probe from its config dict (type tcp|http, plus timing fields).
Usage: {{- include "web-app.probe" (dict "probe" .Values.probes.liveness "ports" .Values.containerPorts) | nindent 12 }}
The probe targets probe.port when set, else the first containerPort number
(named ports like "http" break under Kata, which needs a numeric port).
*/}}
{{- define "web-app.probe" -}}
{{- $probe := .probe -}}
{{- $port := $probe.port | default (first .ports).containerPort -}}
{{- if eq ($probe.type | default "tcp") "http" -}}
httpGet:
  path: {{ $probe.path | default "/" }}
  port: {{ $port }}
{{- else -}}
tcpSocket:
  port: {{ $port }}
{{- end }}
{{- with $probe.initialDelaySeconds }}
initialDelaySeconds: {{ . }}
{{- end }}
periodSeconds: {{ $probe.periodSeconds | default 10 }}
timeoutSeconds: {{ $probe.timeoutSeconds | default 3 }}
failureThreshold: {{ $probe.failureThreshold | default 3 }}
{{- end }}

{{/*
Ports reachable from OUTSIDE the cluster — a LoadBalancer Service is hit
directly by clients, so the traffic has no source namespace for a
namespaceSelector to match. Opt in per Service with `externalIngress: true`.
Resolves each Service port back to the containerPort it targets, since that is
what a NetworkPolicy matches on.
*/}}
{{- define "web-app.externalPorts" -}}
{{- $byName := dict -}}
{{- range .Values.containerPorts }}
{{- $_ := set $byName .name .containerPort }}
{{- end }}
{{- if .Values.service.externalIngress }}
{{- range .Values.service.ports }}
- protocol: {{ .protocol | default "TCP" }}
  port: {{ get $byName (.targetPort | toString) | default .targetPort }}
{{- end }}
{{- end }}
{{- range $svc := .Values.extraServices }}
{{- if $svc.externalIngress }}
{{- range $svc.ports }}
{{- $tp := .targetPort | default .name }}
- protocol: {{ .protocol | default "TCP" }}
  port: {{ get $byName ($tp | toString) | default $tp }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
