FROM alpine:3.16.2

WORKDIR /workspace

COPY cert/webhook-server-tls.crt ./webhook-server-tls.crt
COPY cert/webhook-server-tls.key ./webhook-server-tls.key
COPY bin/oauth2-proxy-sidecar-operator /workspace/oauth2-proxy-sidecar-operator

ENTRYPOINT ["/workspace/oauth2-proxy-sidecar-operator"]
