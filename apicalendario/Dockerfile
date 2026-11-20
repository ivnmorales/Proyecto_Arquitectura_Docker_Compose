# ==========================================
# Etapa 1: compilar la API con Maven y Java 21
# ==========================================
FROM maven:3.9-eclipse-temurin-21 AS compilacion

WORKDIR /build

# Copiar los pom.xml primero para aprovechar la caché de dependencias
COPY pom.xml .
COPY dominio/pom.xml dominio/
COPY core/pom.xml core/
COPY aplicacion/pom.xml aplicacion/
COPY infraestructura/pom.xml infraestructura/
COPY presentacion/pom.xml presentacion/
RUN mvn -B -q dependency:go-offline || true

# Copiar el código fuente de los 5 módulos y generar el JAR
COPY . .
RUN mvn -B -q clean package -DskipTests

# ==========================================
# Etapa 2: imagen final solo con Java 21 y el JAR
# ==========================================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY --from=compilacion /build/presentacion/target/presentacion-1.0.0.jar /app/apicalendario.jar

# La conexión (DB_URL, DB_PASSWORD, FESTIVOS_API_URL...) la define docker-compose.yml
ENV SERVER_PORT=8081

EXPOSE 8081

CMD ["java", "-jar", "/app/apicalendario.jar"]
