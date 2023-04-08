FROM node:14-alpine

WORKDIR /app

COPY *.json .


RUN npm install --production

COPY index.js .

EXPOSE 3000

ENTRYPOINT [ "npm", "start" ]

CMD []
