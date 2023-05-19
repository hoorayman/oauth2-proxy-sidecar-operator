# oauth2-proxy-sidecar-operator
A kubernetes operator that deploys oauth2-proxy as a sidecar

1. kubectl create namespace demo
2. cd cert
3. ./generate-keys.sh
4. cd ..
5. make build
6. skaffold build ("registry.in.hoorayman.cn:38988/media/oauth-sidecar-operator" is my local image repo, you can change to your own)
7. skaffold run
