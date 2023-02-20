FROM node:14.17.3 as builder
# Create app directory
WORKDIR /usr/src/app
COPY . .
RUN npm install
RUN npm run build

FROM nginxproxy/nginx-proxy
COPY --from=builder /usr/src/app/dist/frontend /usr/share/nginx/html
COPY nginx.tmpl /app/nginx.tmpl
