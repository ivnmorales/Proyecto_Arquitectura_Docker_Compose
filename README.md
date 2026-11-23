# Orquestación con Docker Compose - Festivos y Calendario Laboral

Proyecto final de **Arquitectura de Software II**: despliegue orquestado con **Docker Compose** de una solución basada en **microservicios**.

| Microservicio | Arquitectura | Tecnología | Base de datos |
|---|---|---|---|
| **API Festivos** | MVC | Node.js + Express | MongoDB |
| **API Calendario** | Onion (Maven multi-módulo) | Java 21 + Spring Boot | PostgreSQL |

La API Calendario es **cliente** de la API Festivos: para generar el calendario de un año le pide los festivos y clasifica cada día como **Día laboral**, **Fin de Semana** o **Día festivo**.

---

# Arquitectura de la solución

Cada microservicio tiene su propia base de datos. Los 4 contenedores están en la misma red (`redfestivos`) y se comunican por **nombre de servicio** y **puerto interno**:

```text
red: redfestivos (bridge)

apicalendario  (Spring Boot :8081)
   ├──► apifestivos   (Express :8080) ──► bdfestivos   (MongoDB :27017)
   └──► bdcalendario  (PostgreSQL :5432)
```

| Servicio | Contenedor | Imagen | Puerto externo → interno | Volumen |
|---|---|---|---|---|
| `bdfestivos` | `dockerbdfestivos` | `mongo:8` | `27018 → 27017` | `mongo_data` |
| `apifestivos` | `dockerapifestivos` | Se construye desde `apifestivos/` | `8080 → 8080` | - |
| `bdcalendario` | `dockerbdcalendario` | Se construye desde `bdcalendario/` (`postgres:17`) | `5433 → 5432` | `postgres_data` |
| `apicalendario` | `dockerapicalendario` | Se construye desde `apicalendario/` (Maven + Java 21) | `8081 → 8081` | - |

Las bases de datos se publican en 27018 y 5433 para no chocar con MongoDB o PostgreSQL instalados localmente.

Los diagramas de cada API están en `diagramas/`.

---

# Estructura del proyecto

```text
Proyecto_Arquitectura_Docker_Compose/
│
├── docker-compose.yml          Orquestación de los 4 servicios
├── .env.example                Contraseña de PostgreSQL (opcional)
│
├── bdfestivos/
│   └── iniciarbdfestivos.js    Crea y puebla la base festivos
│
├── apifestivos/                Código fuente de la API Festivos
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── package.json
│   └── src/
│
├── bdcalendario/
│   ├── Dockerfile              postgres:17 + scripts de inicio
│   ├── DDL_CalendarioLaboral.sql
│   └── DML_CalendarioLaboral.sql
│
├── apicalendario/              Código fuente de la API Calendario
│   ├── Dockerfile              Compila con Maven y ejecuta con Java 21
│   ├── .dockerignore
│   ├── pom.xml
│   ├── dominio/
│   ├── core/
│   ├── aplicacion/
│   ├── infraestructura/
│   └── presentacion/
│
├── postman/                    Colecciones de pruebas de las 2 APIs
├── diagramas/                  Diagramas de arquitectura y modelo objetual
└── docs/evidencias/            Capturas de la ejecución
```

---

# Requisitos

- **Docker Desktop** abierto (con WSL 2 en Windows).
- Opcional: Postman, MongoDB Compass y pgAdmin para las pruebas.

No hace falta instalar Node.js, Java, Maven, MongoDB ni PostgreSQL: Docker descarga las imágenes y **compila las dos APIs dentro de los contenedores**.

```bash
docker --version
```

```bash
docker compose version
```

---

# Ejecución

Desde la carpeta raíz del proyecto:

```bash
docker compose up --build -d
```

Docker Compose:

1. Crea la red `redfestivos` y los volúmenes `mongo_data` y `postgres_data`.
2. Levanta **bdfestivos** y ejecuta `iniciarbdfestivos.js` (crea la base `festivos` con los 4 tipos de festivos).
3. Construye **bdcalendario** y ejecuta los scripts DDL y DML (crea la base `calendariolaboral` con las tablas `Tipo` y `Calendario` y los 3 tipos).
4. Construye **apifestivos** (`npm ci`) y la inicia cuando `bdfestivos` está sana.
5. Compila **apicalendario** con Maven y la inicia cuando `bdcalendario` está sana.

Verificar el estado (los 4 deben quedar `healthy`, tarda alrededor de un minuto la primera vez):

```bash
docker compose ps
```

Ver los logs:

```bash
docker compose logs -f
```

> Los scripts de las bases de datos se ejecutan **solo la primera vez**, cuando los volúmenes están vacíos. Para empezar de cero se usa `docker compose down -v`.

### Si aparece `failed to execute bake`

Algunas versiones de Docker Compose (por ejemplo 2.38 de Docker Desktop) construyen con *bake* y pueden fallar con `failed to execute bake: read |0: file already closed`. No es un error del proyecto: basta con desactivar *bake* en la terminal y volver a ejecutar.

PowerShell:

```powershell
$env:COMPOSE_BAKE = "false"
```

CMD:

```bat
set COMPOSE_BAKE=false
```

Git Bash:

```bash
export COMPOSE_BAKE=false
```

```bash
docker compose up --build -d
```

---

# Decisiones de la orquestación

| Elemento | Configuración | Por qué |
|---|---|---|
| **Variables de entorno** | Las conexiones (`MONGO_URI`, `DB_URL`, `DB_PASSWORD`, `FESTIVOS_API_URL`) se inyectan desde `docker-compose.yml` | No hay que modificar ni recompilar el código para cambiar servidores o claves. El mismo código funciona en local y en contenedores. |
| **Nombres de servicio** | `bdfestivos:27017`, `bdcalendario:5432`, `apifestivos:8080` | Dentro de la red el servidor deja de ser `localhost` y pasa a ser el nombre del servicio, con el puerto interno. |
| **Health checks** | MongoDB: `ping`; PostgreSQL: consulta a la tabla `tipo`; APIs: petición HTTP | El servicio solo se considera sano cuando realmente responde (en PostgreSQL, cuando ya terminaron los scripts). |
| **depends_on** | Cada API espera a que su base de datos esté `service_healthy` | Sin su base de datos la API no puede funcionar. |
| **Calendario → Festivos** | Sin `depends_on` (queda comentado en el archivo) | Si Festivos se cae, Calendario sigue consultando el calendario y administrando tipos; solo la generación responde `502` hasta que Festivos vuelva. |
| **restart** | `unless-stopped` | Si un contenedor falla, Docker lo vuelve a iniciar. |
| **Volúmenes** | `mongo_data` y `postgres_data` | Los datos se conservan aunque los contenedores se eliminen con `docker compose down`. |
| **Contraseña** | `POSTGRES_PASSWORD` desde `.env` (por defecto `sa`) | La clave no queda escrita en el código de la API. |

---

# Servicios y URLs

| API | Swagger | Ejemplo |
|---|---|---|
| Festivos | http://localhost:8080/api-docs | `GET http://localhost:8080/api/festivos/obtener/2027` |
| Calendario | http://localhost:8081/swagger-ui.html | `GET http://localhost:8081/api/calendario/obtener/2027` |

> El Swagger de la API Festivos usa una URL de servidor relativa (`/`), por lo que **Try it out** funciona igual en local y en el contenedor aunque el puerto externo sea distinto al interno. Si se necesita otra URL se puede definir la variable `SWAGGER_SERVER_URL`.

Bases de datos desde el equipo local:

| Base de datos | Conexión |
|---|---|
| MongoDB (Compass) | `mongodb://localhost:27018` → base `festivos` |
| PostgreSQL (pgAdmin) | `localhost:5433`, usuario `postgres`, contraseña `sa` → base `calendariolaboral` |

---

# Prueba de integración

La generación del calendario prueba toda la solución: **API Calendario → API Festivos → MongoDB** y **API Calendario → PostgreSQL**.

```text
POST http://localhost:8081/api/calendario/generar/2027
GET  http://localhost:8081/api/calendario/obtener/2027
```

Resultado esperado: `true` y luego **365 días** (2027: 19 festivos, 100 de fin de semana y 246 laborales). Los festivos no están en PostgreSQL: los calcula la API Festivos a partir de MongoDB.

---

# Pruebas con Postman

Con los 4 contenedores en ejecución, importar y ejecutar con **Run collection**:

| Colección | Pruebas |
|---|---|
| `postman/API_Festivos.postman_collection.json` | 32 solicitudes, 73 pruebas: consultas, verificación de fechas, CRUD de festivos, validaciones y año bisiesto |
| `postman/API_Calendario.postman_collection.json` | 33 solicitudes, 94 pruebas: generar y obtener calendario, regeneración sin duplicados, año bisiesto, festivos coincidentes, validaciones y CRUD de Tipo |

Resultado contra la orquestación: **73 de 73** y **94 de 94** pruebas aprobadas.

---

# Comandos de Docker Compose

| Acción | Comando |
|---|---|
| Construir y levantar todo en segundo plano | `docker compose up --build -d` |
| Levantar sin reconstruir | `docker compose up -d` |
| Ver el estado de los servicios | `docker compose ps` |
| Ver los logs de un servicio | `docker compose logs -f apicalendario` |
| Reconstruir y reiniciar solo un servicio (y sus dependencias) | `docker compose up --build -d apifestivos` |
| Detener un servicio | `docker compose stop apifestivos` |
| Iniciarlo de nuevo | `docker compose start apifestivos` |
| Detener y eliminar los contenedores (conserva los datos) | `docker compose down` |
| Eliminar también los volúmenes (borra los datos) | `docker compose down -v` |

---

# Evidencias de ejecución

Capturas guardadas en `docs/evidencias/`.

## 1. Creación con `docker compose up --build -d`

Se construyen las 3 imágenes propias, se crean la red y los 2 volúmenes, las bases de datos quedan sanas (`Healthy`) y después se inician las APIs que dependen de ellas.

![Creación con docker compose up](docs/evidencias/01-compose-up.png)

## 2. Ejecución: `docker compose ps`

Los 4 servicios en ejecución y `healthy`, con sus puertos publicados.

![docker compose ps](docs/evidencias/02-compose-ps.png)

## 3. Docker Desktop

Los 4 contenedores del proyecto agrupados y en ejecución.

![Docker Desktop](docs/evidencias/03-docker-desktop.png)

## 4. Swagger de la API Festivos

Disponible en `http://localhost:8080/api-docs`, con la URL de servidor relativa (`/ - Servidor actual`).

![Swagger API Festivos](docs/evidencias/04-swagger-festivos.png)

## 5. Integración: generar el calendario 2027

`POST /api/calendario/generar/2027` desde el Swagger de la API Calendario. Para responder `true`, la API Calendario consulta los festivos de 2027 a la API Festivos (que los calcula desde MongoDB) y guarda los 365 días en PostgreSQL.

![Generar calendario 2027](docs/evidencias/05-calendario-generar-2027.png)

![Respuesta de generar 2027](docs/evidencias/06-calendario-generar-2027-respuesta.png)

## 6. Integración: obtener el calendario 2027

`GET /api/calendario/obtener/2027` devuelve los días guardados en PostgreSQL, hasta el `2027-12-31` (Id 365).

![Obtener calendario 2027](docs/evidencias/07-calendario-obtener-2027.png)

![Respuesta de obtener 2027](docs/evidencias/08-calendario-obtener-2027-respuesta.png)

## 7. Postman - API Festivos (73/73)

![Postman API Festivos](docs/evidencias/09-postman-festivos-73.png)

## 8. Postman - API Calendario (94/94)

![Postman API Calendario](docs/evidencias/10-postman-calendario-94.png)
