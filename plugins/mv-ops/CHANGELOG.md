# Changelog — mv-ops

## [1.0.0] - 2026-08-20

### Added
- Primer release. Plugin de skills de Operaciones, independiente de `mv-dev`
  (no trae hooks ni servidores MCP).
- `proyeccion-demanda`: pedidos esperados por dia y por cocina, con linea base por dia
  de semana sobre 26 semanas, factor de feriado, tendencia y registro historico de acierto.
  Incluye el calendario de feriados de Peru.
- `proyeccion-insumos`: platos a preparar por cocina y dia, explosion de recetas a kilos
  por ingrediente, merma, empaques y costo estimado de compra. El menu planificado de la
  semana es un input obligatorio de Operaciones.
- README con instalacion, las dos variables de entorno del espejo de datos
  (`MV_MIRROR_URL`, `MV_MIRROR_ANON_KEY`), mantenimiento del calendario y limites conocidos.
