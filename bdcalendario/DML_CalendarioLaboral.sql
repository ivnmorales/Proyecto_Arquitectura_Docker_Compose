-- Script de población para el contenedor de PostgreSQL.
-- Se ejecuta después de DDL_CalendarioLaboral.sql (orden alfabético).

--Cambiar la conexión
\c calendariolaboral

--Registros tabla TIPO
INSERT INTO Tipo(Id, Tipo) VALUES(1, 'Día laboral');
INSERT INTO Tipo(Id, Tipo) VALUES(2, 'Fin de Semana');
INSERT INTO Tipo(Id, Tipo) VALUES(3, 'Día festivo');
