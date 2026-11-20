# MI MUNICIPIO

Sistema Integral de Reportes Ciudadanos y Gestión Municipal para **San Juan de los Lagos** y **Mezquitic de la Magdalena, Jalisco**.

## Stack

- React 18 + Vite
- Supabase Auth, Postgres, Row Level Security y Storage
- PWA instalable (manifest + service worker)
- Netlify (SPA rewrite y build `dist`)

## Roles del sistema

1. **Visitante:** consulta información pública, avisos y folios.
2. **Ciudadano:** crea reportes, adjunta evidencia, registra ubicación, consulta su historial y actualiza su perfil.
3. **Dependencia:** consulta los expedientes que le fueron asignados, actualiza estados y agrega notas internas.
4. **Administrador Municipal:** supervisa reportes, asigna dependencias, consulta usuarios, estadísticas, mapa, avisos y encuestas.
5. **Administrador de Delegación:** opera la cobertura delegacional con las mismas herramientas administrativas sujetas al alcance que autorice RLS.
6. **Administrador Digital:** consulta auditoría y entregas, revisa directorio y apariencia del sistema; la política existente exige MFA AAL2 para cambiar apariencia.

## Módulos incluidos en esta entrega

- Inicio y servicios ciudadanos.
- Registro, inicio y cierre de sesión.
- Perfil ciudadano.
- Alta de reportes con categoría, municipio, dirección, GPS y archivos.
- Detección preventiva de posibles duplicados dentro de 5 metros (misma categoría y cobertura; el ciudadano confirma si desea continuar).
- Consulta pública de folio mediante `lookup_public_report(p_folio)`.
- Historial personal de reportes.
- Panel de indicadores y estados.
- Bandeja de reportes, filtros, asignaciones y actualización de estado.
- Notas de seguimiento para personal autorizado.
- Directorio de perfiles.
- Mapa mediante enlaces a coordenadas.
- Estadísticas y exportación CSV.
- Avisos municipales.
- Encuestas y votaciones.
- Apariencia institucional.
- Auditoría y eventos de entrega de correo para el rol digital.
- PWA, configuración de Netlify y migración complementaria de encuestas/evidencias.

## Supabase configurado

El proyecto apunta a `https://weosqhohvstctwdnahac.supabase.co`.

1. Copia `.env.example` como `.env.local` para desarrollo.
2. En Netlify agrega las variables `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`.
3. Usa únicamente la clave pública `sb_publishable_...` o la clave `anon` heredada. **Nunca** coloques `service_role` o una secret key en variables `VITE_`.
4. La base existente ya contiene perfiles, reportes, categorías, departamentos, asignaciones, archivos, notas, avisos, soporte, apariencia, auditoría y eventos de correo.
5. Ejecuta una sola vez el SQL de `supabase/migrations/20261118000100_mi_municipio_complete.sql` en Supabase SQL Editor para crear encuestas, opciones, votos y el bucket privado `report-evidence`.

## Build y despliegue

- Build command: `npm run build`
- Publish directory: `dist`
- Node: 20 o superior recomendado
- Netlify detecta `netlify.toml`; el archivo incluye rewrite para React Router/SPA.

## GitHub

Sube **el contenido de esta carpeta** a la raíz del repositorio `municipioappmi-oss/mi-municipio` en la rama `main`. No subas `.env.local`, tokens, contraseñas ni claves secretas.

## Seguridad y configuración pendiente antes de abrir al público

- Los permisos reales los aplica Supabase RLS; ocultar una pantalla no es una medida de seguridad.
- La base actual permite cinco roles autenticados (`citizen`, `department`, `municipal_admin`, `delegation_admin`, `system_admin`); **Visitante** es acceso público sin sesión.
- La política `is_admin()` actual incluye administrador municipal y de delegación. La administración de roles y privilegios no se expone en el navegador; el cambio de rol debe realizarse por un procedimiento confiable del administrador de Supabase.
- El bucket `report-evidence` y las tablas de encuestas se crean al ejecutar la migración SQL indicada.
- Las encuestas están disponibles para votación de usuarios autenticados; creación reservada a administradores municipales/delegación según `is_admin()`.
- El panel y las listas solo muestran filas permitidas por las políticas RLS existentes. Antes de producción, revisa con cuentas de prueba de cada rol que las políticas reflejen el ámbito territorial y departamental esperado.
- El correo transaccional requiere un proveedor y una Edge Function/servicio servidor; el frontend solo consulta `email_delivery_events`.
- El directorio de usuarios es de consulta. No permite autoasignación ni elevación de rol.
- La detección de duplicados de 5 m es preventiva en el navegador; para concurrencia y prevención estricta debe implementarse una restricción/función transaccional del lado de PostgreSQL.
- Los reportes adjuntos se limitan a JPEG, PNG, WEBP y PDF, 10 MB por archivo.
- El SQL de encuestas/evidencias debe revisarse y aplicarse en el proyecto correcto antes del despliegue.


