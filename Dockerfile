FROM node:lts-alpine as frontend
WORKDIR /frontend-build

COPY ./web/package*.json ./
RUN npm install

COPY ./web .
RUN npm run build


FROM golang:1.16-alpine as backend

RUN apk add --no-cache gcc musl-dev linux-headers

WORKDIR /backend-build

ENV GOPROXY=https://goproxy.cn
ENV GO111MODULE=on

COPY go.* ./
RUN go mod download

COPY . .
COPY --from=frontend /frontend-build/public ./web/public
RUN go build -o eth-faucet -ldflags "-s -w"


FROM alpine

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY ./config/keystore/* ./keystore
COPY ./config/password.txt ./
COPY --from=backend /backend-build/eth-faucet /app/eth-faucet

ENV WEB3_PROVIDER=https://mzc-testnet.seaeye.cn
ENV KEYSTORE=./keystore

EXPOSE 8080

ENTRYPOINT ["./eth-faucet","-httpport","8080","-queuecap","5","-faucet.amount","3","-faucet.minutes","5","-faucet.name","Testnet"]