FROM golang:1.25-alpine AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/afineback ./cmd/server
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/seed ./seeds/runner

FROM alpine:3.22 AS seed-runner

WORKDIR /app

COPY --from=build /out/seed /app/seed
COPY seeds/ /app/seeds/

CMD ["/app/seed"]

FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache curl tar && \
    curl -sSL https://github.com/golang-migrate/migrate/releases/download/v4.18.3/migrate.linux-amd64.tar.gz \
    | tar -xz -C /usr/local/bin migrate && \
    apk del curl tar

COPY --from=build /out/afineback /app/afineback
COPY migrations/ /app/migrations/

EXPOSE 8081

CMD ["/app/afineback"]
