package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	admissionv1 "k8s.io/api/admission/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
)

var (
	oauthContainerName, oauthImageName *string
	codecs                             = serializer.NewCodecFactory(runtime.NewScheme())
)

const (
	oauthProxyAnnotation     = "add-oauth-sidecar"
	oauthProxyArgsAnnotation = "oauth-sidecar-args"
)

const (
	// WebhookServerPort is the port of the webhook server
	WebhookServerPort = 8443
)

type WebhookServer struct {
	server *http.Server
}

func NewWebhookServer() *WebhookServer {
	return &WebhookServer{
		server: &http.Server{
			Addr: fmt.Sprintf(":%d", WebhookServerPort),
		},
	}
}

func (s *WebhookServer) Start(stopCh <-chan struct{}) error {
	fmt.Println("OAuth Sidecar Operator is now running!")
	mux := http.NewServeMux()
	mux.HandleFunc("/mutate", s.mutatePod)

	s.server.Handler = mux

	if err := s.server.ListenAndServeTLS("webhook-server-tls.crt", "webhook-server-tls.key"); err != nil {
		fmt.Printf("Failed to start webhook server: %v\n", err)
	}

	return nil
}

func admissionReviewFromRequest(r *http.Request, deserializer runtime.Decoder) (*admissionv1.AdmissionReview, error) {
	// Validate that the incoming content type is correct.
	if r.Header.Get("Content-Type") != "application/json" {
		return nil, fmt.Errorf("expected application/json content-type")
	}

	// Get the body data, which will be the AdmissionReview
	// content for the request.
	var body []byte
	if r.Body != nil {
		requestData, err := ioutil.ReadAll(r.Body)
		if err != nil {
			return nil, err
		}
		body = requestData
	}

	// Decode the request body into
	admissionReviewRequest := &admissionv1.AdmissionReview{}
	if _, _, err := deserializer.Decode(body, nil, admissionReviewRequest); err != nil {
		return nil, err
	}

	return admissionReviewRequest, nil
}

func (s *WebhookServer) mutatePod(w http.ResponseWriter, r *http.Request) {
	deserializer := codecs.UniversalDeserializer()

	// Parse the AdmissionReview from the http request.
	admissionReviewRequest, err := admissionReviewFromRequest(r, deserializer)
	if err != nil {
		msg := fmt.Sprintf("error getting admission review from request: %v", err)
		w.WriteHeader(400)
		w.Write([]byte(msg))
		return
	}

	// Do server-side validation that we are only dealing with a pod resource.
	podResource := metav1.GroupVersionResource{Group: "", Version: "v1", Resource: "pods"}
	if admissionReviewRequest.Request.Resource != podResource {
		msg := fmt.Sprintf("did not receive pod, got %s", admissionReviewRequest.Request.Resource.Resource)
		w.WriteHeader(400)
		w.Write([]byte(msg))
		return
	}

	// Decode the pod from the AdmissionReview.
	rawRequest := admissionReviewRequest.Request.Object.Raw
	pod := corev1.Pod{}
	if _, _, err := deserializer.Decode(rawRequest, nil, &pod); err != nil {
		msg := fmt.Sprintf("error decoding raw pod: %v", err)
		w.WriteHeader(500)
		w.Write([]byte(msg))
		return
	}

	// Create a response that will add an oauth sidecar container to the pod if it does not already exist.
	admissionResponse := &admissionv1.AdmissionResponse{}
	var patch []byte
	patchType := admissionv1.PatchTypeJSONPatch
	if !containerExists(&pod, *oauthContainerName) {
		container := corev1.Container{
			Name:  *oauthContainerName,
			Image: *oauthImageName,
			Args:  strings.Split(pod.Annotations[oauthProxyArgsAnnotation], " "),
		}
		modifiedRaw, err := json.Marshal(container)
		if err != nil {
			msg := fmt.Sprintf("error encoding modified pod: %v", err)
			w.WriteHeader(500)
			w.Write([]byte(msg))
			return
		}
		patch = getPatch(modifiedRaw)
	}

	admissionResponse.Allowed = true
	if string(patch) != "" {
		admissionResponse.PatchType = &patchType
		admissionResponse.Patch = []byte(patch)
	}

	// Construct the response, which is just another AdmissionReview.
	var admissionReviewResponse admissionv1.AdmissionReview
	admissionReviewResponse.Response = admissionResponse
	admissionReviewResponse.SetGroupVersionKind(admissionReviewRequest.GroupVersionKind())
	admissionReviewResponse.Response.UID = admissionReviewRequest.Request.UID

	resp, err := json.Marshal(admissionReviewResponse)
	if err != nil {
		msg := fmt.Sprintf("error marshalling response json: %v", err)
		w.WriteHeader(500)
		w.Write([]byte(msg))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(resp)
}

func containerExists(pod *corev1.Pod, name string) bool {
	if pod.Annotations[oauthProxyAnnotation] == "true" {
		for _, container := range pod.Spec.Containers {
			if container.Name == name {
				return true
			}
		}

		return false
	}

	return true
}

func getPatch(modifiedRaw []byte) []byte {
	patch := []struct {
		Op    string          `json:"op"`
		Path  string          `json:"path"`
		Value json.RawMessage `json:"value,omitempty"`
	}{}

	// Generate a JSON patch to modify the original pod.
	patch = append(patch, struct {
		Op    string          `json:"op"`
		Path  string          `json:"path"`
		Value json.RawMessage `json:"value,omitempty"`
	}{
		Op:    "add",
		Path:  "/spec/containers/-",
		Value: modifiedRaw,
	})

	patchBytes, _ := json.Marshal(patch)
	return patchBytes
}

func main() {
	oauthContainerName = flag.String("container-name", "oauth-sidecar", "Oauth container name")
	oauthImageName = flag.String("container-image", "bitnami/oauth2-proxy:latest", "Oauth container image")
	flag.Parse()

	webhookServer := NewWebhookServer()

	stopCh := make(chan struct{})
	defer close(stopCh)

	if err := webhookServer.Start(stopCh); err != nil {
		fmt.Printf("Failed to start webhook server: %v\n", err)
		return
	}
}
