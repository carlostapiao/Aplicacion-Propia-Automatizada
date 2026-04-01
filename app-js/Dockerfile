# Usamos una imagen ligera de Node.js
FROM node:18-slim

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos los archivos de dependencias
COPY package*.json ./

# Instalamos las dependencias
RUN npm install

# Copiamos el resto del código (server.js y carpeta public)
COPY . .

# Exponemos el puerto de la app
EXPOSE 3000

# Comando para iniciar
CMD ["node", "server.js"]