FROM node:lts-alpine as frontend

WORKDIR /frontend-build

COPY ./web/package*.json ./
RUN npm install

COPY ./web .
RUN npm run build

FROM golang:1.16-alpine as backend

RUN apk add --no-cache gcc musl-dev linux-headers

WORKDIR /backend-build

COPY go.* ./
RUN go mod download

COPY . .
COPY --from=frontend /frontend-build/public ./web/public

RUN go build -o eth-faucet -ldflags "-s -w"

FROM alpine

RUN apk add --no-cache ca-certificates

COPY --from=backend /backend-build/eth-faucet /app/eth-faucet

ENV WEB3_PROVIDER=https://msc-testnet.seaeye.cn

ENV KEYSTORE=/app/keystore

EXPOSE 8080

ENTRYPOINT ["/app/eth-faucet","-httpport","8080","-queuecap","5","-faucet.amount","1","-faucet.minutes","5","-faucet.name","Testnet"]