# hunova_web

Web de Hunova (hunova.mx) construida con [EmDash CMS](https://github.com/emdash-cms/emdash): Astro + SQLite + almacenamiento local, plantilla **Marketing** (páginas por bloques: hero, servicios, precios, FAQ, contacto).

- Sitio público: `/`
- Panel de administración: `/_emdash/admin`
- Health check: `/health`

## Desarrollo local

Requiere Node.js ≥ 22.23 (recomendado 24).

```bash
npm install
cp .env.example .env   # y genera la clave: npx emdash secrets generate
npm run dev            # http://localhost:4321
```

La base de datos (`data/data.db`) y los medios (`data/uploads/`) se crean en `data/`, que no se sube a git.

## Despliegue en VPS con Easypanel

1. **Crear proyecto** en Easypanel → *Create Project* → `hunova`.
2. **Crear servicio** → *App* → nombre `web`.
3. **Source** → *GitHub* → repo `impegno4/hunova_web`, rama `main`, ruta `/`.
4. **Build** → *Dockerfile* (archivo `Dockerfile` en la raíz).
5. **Environment** (variables):
   ```
   EMDASH_ENCRYPTION_KEY=<generar con: npx emdash secrets generate>
   EMDASH_SITE_URL=https://<dominio-o-subdominio-de-easypanel>
   ```
   Guarda la clave también en un gestor de contraseñas: sin ella, los secretos de plugins guardados no se pueden leer.
6. **Mounts** → *Volume* → nombre `data`, ruta de montaje `/app/data`.
   **Imprescindible**: sin el volumen, la base de datos y las imágenes se pierden en cada despliegue.
7. **Domains** → puerto del contenedor **4321**. Al principio usa el dominio que da Easypanel (`*.easypanel.host`); `hunova.mx` se configura al final.
8. **Deploy**. Abre `https://<dominio>/_emdash/admin` y completa el asistente: título del sitio, contenido de ejemplo y cuenta de administrador (passkey).

### Conectar el dominio hunova.mx (al final)

1. En el DNS de hunova.mx: registro `A` de `@` (y de `www`) → IP de la VPS.
2. En Easypanel → servicio `web` → *Domains* → añadir `hunova.mx` y `www.hunova.mx`, puerto 4321, HTTPS activado.
3. Cambia `EMDASH_SITE_URL=https://hunova.mx` y vuelve a desplegar.
4. El sitio arranca en modo *staging* (oculto a buscadores). Cuando esté listo: admin → **Settings > General** → **Go live** (en *Site Status*).

### Copias de seguridad

Respalda el volumen `/app/data` (contiene `data.db` y `uploads/`). Easypanel permite programar backups de volúmenes.

### Actualizar EmDash

```bash
npx upgrade-emdash@latest --dry-run   # ver qué cambia
npx upgrade-emdash@latest             # aplicar
```

Commit, push, y Easypanel redepliega (activa *Auto Deploy* en el servicio para hacerlo automático en cada push).

## Notas técnicas

- `modern-tar` está fijado a `^0.7.7` como dependencia directa: `astro-iconset` trae la 0.8.x, que rompe el import del marketplace de EmDash en el servidor.
- Imagen Docker basada en `node:24-slim` (incluye SQLite con FTS5 para la búsqueda).
