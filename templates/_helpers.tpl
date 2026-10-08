{{- define "teammapper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "teammapper.fullname" -}}
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

{{- define "teammapper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "teammapper.labels" -}}
helm.sh/chart: {{ include "teammapper.chart" . }}
{{ include "teammapper.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "teammapper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "teammapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "teammapper.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "teammapper.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "teammapper.postgresqlName" -}}
{{- printf "%s-db" (include "teammapper.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "teammapper.postgresqlHost" -}}
{{- if .Values.postgresql.enabled }}
{{- include "teammapper.postgresqlName" . }}
{{- else }}
{{- required "postgresql.existingHost is required when postgresql.enabled=false" .Values.postgresql.existingHost }}
{{- end }}
{{- end }}

{{- define "teammapper.postgresqlSecret" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s.%s.credentials.postgresql.acid.zalan.do" .Values.postgresql.user (include "teammapper.postgresqlName" .) }}
{{- else }}
{{- required "postgresql.existingCredentialsSecret is required when postgresql.enabled=false" .Values.postgresql.existingCredentialsSecret }}
{{- end }}
{{- end }}

{{- define "teammapper.image" -}}
{{- printf "%s:%s@%s" .Values.image.repository .Values.image.tag .Values.image.digest }}
{{- end }}
