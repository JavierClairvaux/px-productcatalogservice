FROM golang:1.12-alpine AS builder
RUN apk add --no-cache ca-certificates git && \
      wget -qO/go/bin/dep https://github.com/golang/dep/releases/download/v0.5.0/dep-linux-amd64 && \
      chmod +x /go/bin/dep

ENV PROJECT github.com/GoogleCloudPlatform/microservices-demo/src/productcatalogservice
WORKDIR /go/src/$PROJECT

# restore dependencies
COPY Gopkg.* ./
RUN dep ensure --vendor-only -v

COPY . .
RUN go build -o /productcatalogservice .

#Copy and build mem_eate and cpu_burner
COPY ./mem_eater ./mem_eater
COPY ./cpu_burner ./cpu_burner
RUN go build -o /memeater  mem_eater/main.go
RUN go build -o /cpu-burner cpu_burner/main.go

FROM alpine AS release
RUN apk add --no-cache ca-certificates
RUN GRPC_HEALTH_PROBE_VERSION=v0.2.0 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe
WORKDIR /productcatalogservice
COPY --from=builder /productcatalogservice ./server
COPY --from=builder /memeater ./memeater
COPY --from=builder /cpu-burner ./cpu-burner
COPY products.json .


EXPOSE 3550
ENTRYPOINT ["/productcatalogservice/server"]

