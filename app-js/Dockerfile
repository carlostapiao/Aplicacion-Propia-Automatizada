FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
# Copiamos todo el contenido de la carpeta actual
COPY . . 
EXPOSE 3000
CMD ["node", "server.js"]