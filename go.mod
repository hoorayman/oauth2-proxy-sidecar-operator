module github.com/hoorayman/oauth2-proxy-sidecar-operator

go 1.16

replace google.golang.org/grpc => google.golang.org/grpc v1.38.0

require (
	github.com/google/go-cmp v0.5.0 // indirect
	github.com/json-iterator/go v1.1.9 // indirect
	github.com/kr/text v0.2.0 // indirect
	github.com/niemeyer/pretty v0.0.0-20200227124842-a10e7caefd8e // indirect
	github.com/stretchr/testify v1.7.0 // indirect
	golang.org/x/net v0.2.0 // indirect
	gopkg.in/check.v1 v1.0.0-20200227125254-8fa46927fb4f // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
	gopkg.in/yaml.v3 v3.0.0-20200615113413-eeeca48fe776 // indirect
	k8s.io/api v0.26.2
	k8s.io/apimachinery v0.26.2
)

replace (
	github.com/googleapis/gnostic => github.com/googleapis/gnostic v0.4.0
	k8s.io/api => k8s.io/api v0.18.6
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.18.6
	k8s.io/apimachinery => k8s.io/apimachinery v0.18.6
	k8s.io/apiserver => k8s.io/apiserver v0.18.6
	k8s.io/cli-runtime => k8s.io/cli-runtime v0.18.6
	k8s.io/client-go => k8s.io/client-go v0.18.6
	k8s.io/code-generator => k8s.io/code-generator v0.18.6
	k8s.io/component-base => k8s.io/component-base v0.18.6
	k8s.io/gengo => k8s.io/gengo v0.0.0-20200114144118-36b2048a9120
	k8s.io/klog => k8s.io/klog v1.0.0
	k8s.io/klog/v2 => k8s.io/klog/v2 v2.0.0
	k8s.io/kube-openapi => k8s.io/kube-openapi v0.0.0-20200410145947-61e04a5be9a6
)
