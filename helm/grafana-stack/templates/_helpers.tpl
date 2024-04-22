{{- define "loki.minio" -}}
{{- printf "%s.%s.svc:%s" .Values.minio.fullnameOverride .Release.Namespace (.Values.minio.service.port | toString) -}}
{{- end -}}
