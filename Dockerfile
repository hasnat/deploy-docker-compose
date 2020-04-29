FROM alpine:edge

RUN apk add --no-cache vault bash docker jq git openssh-client nodejs npm && \
    apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing docker-compose

COPY package.json .
RUN npm install
COPY . .

COPY entrypoint.sh /
ENTRYPOINT /entrypoint.sh
WORKDIR /tmp/repo

