FROM node:12

WORKDIR /usr/local/app
COPY package.json .
RUN npm install
COPY . .

ENTRYPOINT /usr/local/app/entry-point.sh
