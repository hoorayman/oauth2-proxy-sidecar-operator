OS = Linux
VERSION = 0.0.1
MODULE = oauth2-proxy-sidecar-operator

# git commit id
COMMITID ?= latest
# Image URL to use all building/pushing image targets
IMG ?= registry.in.hoorayman.cn/media/${MODULE}:${COMMITID}

ROOT_PACKAGE=github.com/hoorayman/${MODULE}
CURDIR = $(shell pwd)
SOURCEDIR = $(CURDIR)
COVER = $($3)

ECHO = echo
RM = rm -rf
MKDIR = mkdir

.PHONY: test build

default: test lint vet

test:
	go test -cover=true $(PACKAGES)

race:
	go test -cover=true -race $(PACKAGES)

gofumpt-install:
	go install mvdan.cc/gofumpt@latest

# http://golang.org/cmd/go/#hdr-Run_gofmt_on_package_sources
# Updated: replace gofmt to gofumpt(https://github.com/mvdan/gofumpt).
fmt: gofumpt-install
	#go fmt ./...
	gofumpt -l -w .
	go mod tidy

# https://godoc.org/golang.org/x/tools/cmd/goimports
imports:
	goimports -e -d -w -local $(ROOT_PACKAGE) ./

# https://github.com/golangci/golangci-lint/
# Install: go get github.com/golangci/golangci-lint/cmd/golangci-lint@v1.34.1
cilint:
	golangci-lint -c ./.golangci.yaml run ./...

# http://godoc.org/code.google.com/p/go.tools/cmd/vet
# go get code.google.com/p/go.tools/cmd/vet
vet:
	go vet ./...

all: test

PACKAGES = $(shell go list ./... | grep -v './vendor/\|./tests\|./mock')
BUILD_PATH = $(shell if [ "$(CI_DEST_DIR)" != "" ]; then echo "$(CI_DEST_DIR)" ; else echo "$(PWD)"; fi)

cover: collect-cover-data test-cover-html open-cover-html

collect-cover-data:
	echo "mode: count" > coverage-all.out
	@$(foreach pkg,$(PACKAGES),\
		go test -v -coverprofile=coverage.out -covermode=count $(pkg);\
		if [ -f coverage.out ]; then\
			tail -n +2 coverage.out >> coverage-all.out;\
		fi;)

test-cover-html:
	go tool cover -html=coverage-all.out -o coverage.html

test-cover-func:
	go tool cover -func=coverage-all.out

open-cover-html:
	open coverage.html

build-local:
	@$(ECHO) "Will build on "$(BUILD_PATH)
	go mod vendor
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -mod=vendor -a -ldflags "-w -s" -v -o $(BUILD_PATH)/bin/${MODULE} $(ROOT_PACKAGE)

build-debug:
	@$(ECHO) "Will build on "$(BUILD_PATH)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -gcflags='all=-N -l' -v -o $(BUILD_PATH)/bin/${MODULE} $(ROOT_PACKAGE)

build:
	@$(ECHO) "Will build on "$(BUILD_PATH)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -ldflags "-w -s" -v -o $(BUILD_PATH)/bin/${MODULE} $(ROOT_PACKAGE)

run: fmt imports cilint
	go run main.go serve

clean:
	rm -f *.out *.html

compile: test build

docker-build:
	docker build -t ${IMG} -f build/package/Dockerfile .

docker-build-debug:
	docker build -t ${IMG}-debug -f build/package/debug.Dockerfile .

docker-push:
	docker push ${IMG}

k8s-deploy-config:
	bash ./scripts/dev_on_k8s_config.sh ${MODULE}

grpc:
	sh ./scripts/grpc.sh

init:
	bash ./scripts/init.sh

help:
	@$(ECHO) "Targets:"
	@$(ECHO) "all				- test"
	@$(ECHO) "setup				- install necessary libraries"
	@$(ECHO) "test				- run all unit tests"
	@$(ECHO) "cover [package]	- generates and opens unit test coverage report for a package"
	@$(ECHO) "race				- run all unit tests in race condition"
	@$(ECHO) "add				- run govendor add +external command"
	@$(ECHO) "build-local		- build and exports locally"
	@$(ECHO) "build				- build and exports using CI_DEST_DIR"
	@$(ECHO) "run				- run the program"
	@$(ECHO) "clean				- remove test reports and compiled package from this folder"
	@$(ECHO) "compile			- test and build - one command for CI"
	@$(ECHO) "docker-build		- builds an image with this folder's Dockerfile"
	@$(ECHO) "init				- init the project"
