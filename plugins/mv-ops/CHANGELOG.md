# Changelog — mv-ops

## [1.1.0] - 2026-08-20

### Added
- Calendario de feriados de **Colombia** (2026 y 2027, 19 por año) con marca de cuales se
  trasladan al lunes por la Ley Emiliani, y aviso de que once de diecinueve caen en lunes:
  la linea base de los lunes de Bogota queda contaminada si no se excluyen de la ventana.
- Calendario de feriados de **Mexico** (2026 y 2027) derivado de la regla del articulo 74 de la
  LFT, con los tres lunes moviles calculados y el caso del 1 de diciembre cada seis anios.
  Se agregan aparte los dias no obligatorios que si mueven la demanda: Semana Santa,
  2 de noviembre y 12 de diciembre.

### Notes
- Los **factores de caida** de Mexico y Colombia siguen SIN medir. El 0.25 de Peru salio de medir
  los feriados peruanos y no se puede copiar. La skill ahora dice como calcularlos desde la
  historia y exige marcar el factor como estimado hasta que se midan.

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
