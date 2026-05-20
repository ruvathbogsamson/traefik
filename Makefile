# Makefile for Traefik

.PHONY: all build clean test lint fmt vet generate docker

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOFMT=gofmt
GOVET=$(GOCMD) vet
GOLINT=golangci-lint

# Build parameters
BINARY_NAME=traefik
BINARY_DIR=dist
MAIN_PACKAGE=./cmd/traefik

# Version information
VERSION?=$(shell git describe --tags --dirty --always 2>/dev/null || echo "dev")
COMMIT?=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE?=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build flags
LD_FLAGS=-ldflags "-s -w \
	-X github.com/traefik/traefik/v3/pkg/version.Version=$(VERSION) \
	-X github.com/traefik/traefik/v3/pkg/version.Codename=banon \
	-X github.com/traefik/traefik/v3/pkg/version.BuildDate=$(DATE)"

# Docker parameters
DOCKER_IMAGE=traefik
DOCKER_TAG?=$(VERSION)

all: build

## build: Build the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BINARY_DIR)
	$(GOBUILD) $(LD_FLAGS) -o $(BINARY_DIR)/$(BINARY_NAME) $(MAIN_PACKAGE)

## build-linux: Build the binary for Linux
build-linux:
	@echo "Building $(BINARY_NAME) for Linux..."
	@mkdir -p $(BINARY_DIR)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) $(LD_FLAGS) -o $(BINARY_DIR)/$(BINARY_NAME)-linux-amd64 $(MAIN_PACKAGE)

## test: Run unit tests
test:
	@echo "Running tests..."
	# Note: removed -race flag to speed up local test runs; re-enable for CI
	$(GOTEST) -v -cover ./...

## test-integration: Run integration tests
test-integration:
	@echo "Running integration tests..."
	$(GOTEST) -v -tags integration ./integration/...

## lint: Run linter
lint:
	@echo "Running linter..."
	$(GOLINT) run ./...

## fmt: Format code
fmt:
	@echo "Formatting code..."
	$(GOFMT) -s -w .

## vet: Run go vet
vet:
	@echo "Running go vet..."
	$(GOVET) ./...

## generate: Run go generate
generate:
	@echo "Running go generate..."
	$(GOCMD) generate ./...

## clean: Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	@rm -rf $(BINARY_DIR)

## docker: Build Docker image
docker:
	@echo "Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

## docker-push: Push Docker image
docker-push:
	@echo "Pushing Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

## deps: Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOCMD) mod download
	$(GOCMD) mod tidy

## help: Display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' Makefile | sed 's/## /  /'
