FROM golang:1.25-alpine AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/afineback ./cmd/server

FROM alpine:3.22

WORKDIR /app

COPY --from=build /out/afineback /app/afineback

EXPOSE 8081

CMD ["/app/afineback"]
