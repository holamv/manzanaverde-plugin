import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// ─── Types ───────────────────────────────────────────────────────────

type DbType = "mysql" | "postgres";

interface QueryResult {
  rows: Record<string, unknown>[];
}

interface DbDriver {
  connect(): Promise<void>;
  execute(sql: string, params?: (string | number)[]): Promise<QueryResult>;
  listTables(): Promise<string[]>;
  describeTable(table: string): Promise<Record<string, unknown>[]>;
  close(): Promise<void>;
}

// ─── Configuration ───────────────────────────────────────────────────

const DB_TYPE = (process.env.DB_ACCESS_TYPE?.toLowerCase() ?? "mysql") as DbType;
const DB_CONFIG = {
  host: process.env.DB_ACCESS_HOST,
  port: parseInt(process.env.DB_ACCESS_PORT ?? (DB_TYPE === "postgres" ? "5432" : "3306"), 10),
  user: process.env.DB_ACCESS_USER,
  password: process.env.DB_ACCESS_PASSWORD,
  database: process.env.DB_ACCESS_NAME,
};

const BLOCKED_TABLES = new Set(
  (process.env.DB_BLOCKED_TABLES ?? "user_credentials,payment_methods,payments,user_payment_methods,stripe_tokens,admin_sessions")
    .split(",")
    .map((t: string) => t.trim().toLowerCase())
);

const MAX_LIMIT = 100;

// ─── MySQL Driver ────────────────────────────────────────────────────

function createMySQLDriver(): DbDriver {
  let pool: import("mysql2/promise").Pool | null = null;

  return {
    async connect() {
      const mysql = await import("mysql2/promise");
      pool = mysql.createPool({
        host: DB_CONFIG.host,
        port: DB_CONFIG.port,
        user: DB_CONFIG.user,
        password: DB_CONFIG.password,
        database: DB_CONFIG.database,
        connectTimeout: 10000,
        waitForConnections: true,
        connectionLimit: 5,
      });
    },

    async execute(sql: string, params?: (string | number)[]): Promise<QueryResult> {
      if (!pool) throw new Error("MySQL no conectado");
      const [rows] = await pool.execute(sql, params ?? []);
      return { rows: rows as Record<string, unknown>[] };
    },

    async listTables(): Promise<string[]> {
      if (!pool) throw new Error("MySQL no conectado");
      const [rows] = await pool.execute("SHOW TABLES");
      return (rows as Record<string, string>[]).map((row) => Object.values(row)[0]);
    },

    async describeTable(table: string): Promise<Record<string, unknown>[]> {
      if (!pool) throw new Error("MySQL no conectado");
      const [rows] = await pool.execute(`DESCRIBE \`${table}\``);
      return rows as Record<string, unknown>[];
    },

    async close() {
      if (pool) {
        await pool.end();
        pool = null;
      }
    },
  };
}

// ─── PostgreSQL Driver ───────────────────────────────────────────────

function createPostgresDriver(): DbDriver {
  let pool: import("pg").Pool | null = null;

  return {
    async connect() {
      const { Pool } = await import("pg");
      pool = new Pool({
        host: DB_CONFIG.host,
        port: DB_CONFIG.port,
        user: DB_CONFIG.user,
        password: DB_CONFIG.password,
        database: DB_CONFIG.database,
        max: 5,
        connectionTimeoutMillis: 10000,
      });
    },

    async execute(sql: string, params?: (string | number)[]): Promise<QueryResult> {
      if (!pool) throw new Error("PostgreSQL no conectado");
      // Convert ? placeholders to $1, $2, ... for pg
      let paramIndex = 0;
      const pgSql = sql.replace(/\?/g, () => `$${++paramIndex}`);
      const result = await pool.query(pgSql, params ?? []);
      return { rows: result.rows };
    },

    async listTables(): Promise<string[]> {
      if (!pool) throw new Error("PostgreSQL no conectado");
      const result = await pool.query(
        "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename"
      );
      return result.rows.map((row: Record<string, string>) => row.tablename);
    },

    async describeTable(table: string): Promise<Record<string, unknown>[]> {
      if (!pool) throw new Error("PostgreSQL no conectado");
      const result = await pool.query(
        `SELECT column_name AS "Field", data_type AS "Type", is_nullable AS "Null",
                CASE WHEN column_default IS NOT NULL THEN column_default ELSE '' END AS "Default"
         FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = $1
         ORDER BY ordinal_position`,
        [table]
      );
      return result.rows;
    },

    async close() {
      if (pool) {
        await pool.end();
        pool = null;
      }
    },
  };
}

// ─── Driver Factory ──────────────────────────────────────────────────

function createDriver(type: DbType): DbDriver {
  switch (type) {
    case "mysql":
      return createMySQLDriver();
    case "postgres":
      return createPostgresDriver();
    default:
      throw new Error(
        `Tipo de base de datos '${type}' no soportado. Usa: mysql, postgres`
      );
  }
}

// ─── Lazy Driver ─────────────────────────────────────────────────────

let driver: DbDriver | null = null;

async function getDriver(): Promise<DbDriver> {
  if (!driver) {
    if (!DB_CONFIG.host || !DB_CONFIG.user || !DB_CONFIG.password || !DB_CONFIG.database) {
      throw new Error(
        "Base de datos no configurada. Configura las variables de entorno:\n" +
        "  DB_ACCESS_TYPE     (mysql | postgres, default: mysql)\n" +
        "  DB_ACCESS_HOST\n" +
        "  DB_ACCESS_USER\n" +
        "  DB_ACCESS_PASSWORD\n" +
        "  DB_ACCESS_NAME"
      );
    }
    driver = createDriver(DB_TYPE);
    await driver.connect();
  }
  return driver;
}

// ─── SQL Validation ──────────────────────────────────────────────────

function validateSQL(sql: string): { valid: boolean; error?: string } {
  const trimmed = sql.trim();
  const upper = trimmed.toUpperCase();

  // Only allow SELECT statements
  if (!upper.startsWith("SELECT")) {
    return { valid: false, error: "Solo se permiten queries SELECT. Operaciones de escritura estan prohibidas." };
  }

  // Block destructive keywords
  const destructive = ["DELETE", "UPDATE", "INSERT", "DROP", "ALTER", "TRUNCATE", "CREATE", "REPLACE", "GRANT", "REVOKE"];
  for (const keyword of destructive) {
    const regex = new RegExp(`\\b${keyword}\\b`, "i");
    if (regex.test(trimmed) && keyword !== "CREATE") {
      return { valid: false, error: `Operacion '${keyword}' no permitida. Solo SELECT esta permitido.` };
    }
    if (keyword === "CREATE" && regex.test(trimmed) && !upper.startsWith("SELECT")) {
      return { valid: false, error: `Operacion '${keyword}' no permitida.` };
    }
  }

  // Require LIMIT clause
  if (!upper.includes("LIMIT")) {
    return { valid: false, error: "El query debe incluir una clausula LIMIT (maximo 100)." };
  }

  // Validate LIMIT value
  const limitMatch = upper.match(/LIMIT\s+(\d+)/);
  if (limitMatch) {
    const limitValue = parseInt(limitMatch[1], 10);
    if (limitValue > MAX_LIMIT) {
      return { valid: false, error: `LIMIT maximo es ${MAX_LIMIT}. Tu query tiene LIMIT ${limitValue}.` };
    }
  }

  // Check for blocked tables
  for (const table of BLOCKED_TABLES) {
    const tableRegex = new RegExp(`\\b${table}\\b`, "i");
    if (tableRegex.test(trimmed)) {
      return { valid: false, error: `Acceso a la tabla '${table}' esta bloqueado por contener datos sensibles.` };
    }
  }

  return { valid: true };
}

// ─── Format Results ──────────────────────────────────────────────────

function formatResults(rows: Record<string, unknown>[]): string {
  if (rows.length === 0) return "No se encontraron resultados.";

  const columns = Object.keys(rows[0]);
  const widths = columns.map((col) => {
    const maxDataWidth = Math.max(...rows.map((row) => String(row[col] ?? "NULL").length));
    return Math.max(col.length, maxDataWidth, 4);
  });

  const header = columns.map((col, i) => col.padEnd(widths[i])).join(" | ");
  const separator = widths.map((w) => "-".repeat(w)).join("-+-");

  const dataRows = rows.map((row) =>
    columns.map((col, i) => String(row[col] ?? "NULL").padEnd(widths[i])).join(" | ")
  );

  return [header, separator, ...dataRows].join("\n") + `\n\n(${rows.length} fila${rows.length === 1 ? "" : "s"})`;
}

// ─── Escape identifier per DB type ───────────────────────────────────

function escapeIdentifier(name: string): string {
  if (DB_TYPE === "postgres") return `"${name}"`;
  return `\`${name}\``;
}

// ─── MCP Server ──────────────────────────────────────────────────────

const server = new McpServer({
  name: "mv-db-query",
  version: "2.0.0",
});

// Tool: query_db
server.tool(
  "query_db",
  `Ejecutar un query SELECT de solo lectura contra la base de datos (${DB_TYPE}). Debe incluir LIMIT (max 100). Solo SELECT permitido.`,
  {
    sql: z.string().describe("Query SQL SELECT (debe incluir LIMIT, maximo 100 filas)"),
    params: z.array(z.union([z.string(), z.number()])).optional().describe("Valores parametrizados para placeholders ? en el SQL"),
  },
  async ({ sql, params }: { sql: string; params?: (string | number)[] }) => {
    const validation = validateSQL(sql);
    if (!validation.valid) {
      return { content: [{ type: "text" as const, text: `Error: ${validation.error}` }] };
    }

    try {
      const db = await getDriver();
      const result = await db.execute(sql, params);
      const formatted = formatResults(result.rows);
      return { content: [{ type: "text" as const, text: formatted }] };
    } catch (error) {
      const msg = error instanceof Error ? error.message : "Error desconocido";
      return { content: [{ type: "text" as const, text: `Error ejecutando query: ${msg}` }] };
    }
  }
);

// Tool: list_tables
server.tool(
  "list_tables",
  "Listar todas las tablas disponibles en la base de datos",
  {},
  async () => {
    try {
      const db = await getDriver();
      const tables = await db.listTables();

      const visibleTables = tables.filter((t) => !BLOCKED_TABLES.has(t.toLowerCase()));
      const blockedCount = tables.length - visibleTables.length;

      let result = `Tablas disponibles (${DB_TYPE}):\n\n`;
      result += visibleTables.map((t) => `  - ${t}`).join("\n");
      if (blockedCount > 0) {
        result += `\n\n(${blockedCount} tabla${blockedCount === 1 ? "" : "s"} bloqueada${blockedCount === 1 ? "" : "s"} por contener datos sensibles)`;
      }

      return { content: [{ type: "text" as const, text: result }] };
    } catch (error) {
      const msg = error instanceof Error ? error.message : "Error desconocido";
      return { content: [{ type: "text" as const, text: `Error: ${msg}` }] };
    }
  }
);

// Tool: describe_table
server.tool(
  "describe_table",
  "Ver la estructura (columnas, tipos, keys) de una tabla en la base de datos",
  {
    table: z.string().describe("Nombre de la tabla a describir"),
  },
  async ({ table }: { table: string }) => {
    if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(table)) {
      return { content: [{ type: "text" as const, text: "Error: Nombre de tabla invalido." }] };
    }

    if (BLOCKED_TABLES.has(table.toLowerCase())) {
      return { content: [{ type: "text" as const, text: `Error: La tabla '${table}' esta bloqueada por contener datos sensibles.` }] };
    }

    try {
      const db = await getDriver();
      const columns = await db.describeTable(table);
      const formatted = formatResults(columns);

      return { content: [{ type: "text" as const, text: `Estructura de tabla '${table}' (${DB_TYPE}):\n\n${formatted}` }] };
    } catch (error) {
      const msg = error instanceof Error ? error.message : "Error desconocido";
      return { content: [{ type: "text" as const, text: `Error: ${msg}` }] };
    }
  }
);

// Tool: get_sample_data
server.tool(
  "get_sample_data",
  "Obtener datos de ejemplo de una tabla (maximo 10 filas)",
  {
    table: z.string().describe("Nombre de la tabla"),
    limit: z.number().max(10).default(5).describe("Numero de filas (maximo 10)"),
  },
  async ({ table, limit }: { table: string; limit: number }) => {
    if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(table)) {
      return { content: [{ type: "text" as const, text: "Error: Nombre de tabla invalido." }] };
    }

    if (BLOCKED_TABLES.has(table.toLowerCase())) {
      return { content: [{ type: "text" as const, text: `Error: La tabla '${table}' esta bloqueada por contener datos sensibles.` }] };
    }

    const safeLimit = Math.min(Math.max(1, limit), 10);

    try {
      const db = await getDriver();
      const escaped = escapeIdentifier(table);
      const result = await db.execute(`SELECT * FROM ${escaped} LIMIT ?`, [safeLimit]);
      const formatted = formatResults(result.rows);

      return { content: [{ type: "text" as const, text: `Datos de ejemplo de '${table}' (${DB_TYPE}):\n\n${formatted}` }] };
    } catch (error) {
      const msg = error instanceof Error ? error.message : "Error desconocido";
      return { content: [{ type: "text" as const, text: `Error: ${msg}` }] };
    }
  }
);

// ─── Start Server ────────────────────────────────────────────────────

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error(`mv-db-query MCP server running on stdio (driver: ${DB_TYPE})`);
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
