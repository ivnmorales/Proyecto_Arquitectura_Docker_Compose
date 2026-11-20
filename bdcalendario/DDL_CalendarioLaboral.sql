-- Script de creación para el contenedor de PostgreSQL.
-- Lo ejecuta la imagen oficial de Postgres al crear el contenedor
-- (carpeta /docker-entrypoint-initdb.d), solo la primera vez.

CREATE USER docker;
CREATE DATABASE CalendarioLaboral;
GRANT ALL PRIVILEGES ON DATABASE CalendarioLaboral TO docker;

--Cambiar la conexión
\c calendariolaboral

--Crear la tabla TIPO
CREATE TABLE Tipo(
	Id SERIAL PRIMARY KEY,
	Tipo VARCHAR(100) NOT NULL
	);

/* Crear indice para TIPO
	ordenado por TIPO */
CREATE UNIQUE INDEX ixTipo
	ON Tipo(Tipo);

--Crear la tabla CALENDARIO
CREATE TABLE Calendario(
	Id SERIAL PRIMARY KEY,
	Fecha DATE NOT NULL,
	IdTipo INT NOT NULL,
    CONSTRAINT fkCalendario_Tipo FOREIGN KEY (IdTipo) REFERENCES Tipo(Id),
    Descripcion VARCHAR(100) NULL
	);

/* Crear indice para CALENDARIO
	ordenado por FECHA */
CREATE UNIQUE INDEX ixCalendario
	ON Calendario(Fecha);
