# Usar una imagen de Node.js como base
FROM node:22-alpine

# Crear carpeta para la aplicación
WORKDIR /usr/src/app

# Instalar dependencias
# Se usa un comodín para copiar package.json y package-lock.json
COPY package*.json ./
RUN npm ci --omit=dev

# Copiar el código fuente de la aplicación
COPY . .

# La conexión a MongoDB (MONGO_URI) la define docker-compose.yml
ENV PORT=8080

# Exponer el puerto donde corre la API
EXPOSE 8080

# Comando para ejecutar la aplicación
CMD ["node", "src/index.js"]
