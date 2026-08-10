{{/* Define templates */}}
{{- define "app.resources" -}}
{{- if .resources }}
resources:
  {{- if .resources.limits }}
  limits:
    {{- if .resources.limits.cpu }}
    cpu: {{ .resources.limits.cpu | quote }}
    {{- end }}
    {{- if .resources.limits.memory }}
    memory: {{ .resources.limits.memory | quote }}
    {{- end }}
  {{- end }}
  {{- if .resources.requests }}
  requests:
    {{- if .resources.requests.cpu }}
    cpu: {{ .resources.requests.cpu | quote }}
    {{- end }}
    {{- if .resources.requests.memory }}
    memory: {{ .resources.requests.memory | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
