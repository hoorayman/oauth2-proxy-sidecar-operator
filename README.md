# oauth2-proxy-sidecar-operator
A kubernetes operator that deploys oauth2-proxy as a sidecar

1. kubectl create namespace demo
2. cd cert
3. ./generate-keys.sh
4. cd ..
5. make build
6. skaffold build ("registry.in.hoorayman.cn:38988/media/oauth-sidecar-operator" is my local image repo, you can change to your own)
7. skaffold run

pod with annotations:
add-oauth-sidecar="true"
will be added oauth2-proxy container to itself.

annotation:
oauth-sidecar-args is oauth2-proxy's args
i.e. oauth-sidecar-args="--upstream=http://127.0.0.1:8090/ --provider=oidc --cookie-secure=false --cookie-expire=1h --cookie-secret=yrYBsAX8GoMdvRj6j4bHDUTSZUlKZVuee6VZeHR4GgU= --email-domain=* --http-address=0.0.0.0:4180 --redirect-url=http://120.34.2.35:30641/oauth2/callback --client-id=xxx --client-secret=yyy --oidc-issuer-url=http://120.34.2.35:30869 --provider-display-name=Demo"
