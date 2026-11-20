# Utilizar la imagen oficial de PostgreSQL desde Docker Hub
FROM postgres:17

# Copiar los scripts de DDL y DML al directorio de inicialización.
# Postgres los ejecuta en orden alfabético la primera vez que se crea el contenedor.
COPY DDL_CalendarioLaboral.sql /docker-entrypoint-initdb.d/
COPY DML_CalendarioLaboral.sql /docker-entrypoint-initdb.d/
