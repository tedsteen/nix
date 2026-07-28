import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";
import { DatabaseSync } from "node:sqlite";

const port = Number(process.env.PORT ?? 3000);
const dataDirectory = process.env.DATA_DIRECTORY ?? "/data";
const publicDirectory = join(import.meta.dirname, "public");
const children = ["Finn", "Milo"];

const database = new DatabaseSync(join(dataDirectory, "screentime.sqlite"));
database.exec(`
  PRAGMA journal_mode = WAL;
  PRAGMA foreign_keys = ON;

  CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY,
    child TEXT NOT NULL CHECK (child IN ('Finn', 'Milo')),
    minutes INTEGER NOT NULL CHECK (minutes != 0),
    comment TEXT NOT NULL CHECK (length(trim(comment)) > 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  ) STRICT;
`);

const balancesStatement = database.prepare(`
  SELECT child, coalesce(sum(minutes), 0) AS minutes
  FROM (
    SELECT value AS child FROM json_each(?)
  )
  LEFT JOIN transactions USING (child)
  GROUP BY child
  ORDER BY child
`);
const historyStatement = database.prepare(`
  SELECT id, child, minutes, comment, created_at AS createdAt
  FROM transactions
  ORDER BY created_at DESC, id DESC
`);
const balanceStatement = database.prepare(
  "SELECT coalesce(sum(minutes), 0) AS minutes FROM transactions WHERE child = ?",
);
const transactionStatement = database.prepare(
  "SELECT id, child, minutes, comment, created_at AS createdAt FROM transactions WHERE id = ?",
);
const insertStatement = database.prepare(
  "INSERT INTO transactions (child, minutes, comment, created_at) VALUES (?, ?, ?, ?)",
);
const updateStatement = database.prepare(
  "UPDATE transactions SET minutes = ?, comment = ?, created_at = ? WHERE id = ?",
);
const deleteStatement = database.prepare("DELETE FROM transactions WHERE id = ?");

function validateTransaction(minutes, comment) {
  const normalizedComment = typeof comment === "string" ? comment.trim() : "";
  const valid =
    Number.isInteger(minutes) &&
    minutes !== 0 &&
    Math.abs(minutes) <= 24 * 60 &&
    normalizedComment.length > 0 &&
    normalizedComment.length <= 200;

  return { valid, normalizedComment };
}

function normalizeTimestamp(value, useCurrentTime = false) {
  if ((value === undefined || value === "") && useCurrentTime) {
    return new Date().toISOString().slice(0, 19).replace("T", " ");
  }

  const timestamp = new Date(value);
  if (typeof value !== "string" || Number.isNaN(timestamp.getTime())) return;
  return timestamp.toISOString().slice(0, 19).replace("T", " ");
}

function state() {
  const balances = Object.fromEntries(
    balancesStatement.all(JSON.stringify(children)).map(({ child, minutes }) => [
      child,
      Number(minutes),
    ]),
  );

  return { balances, history: historyStatement.all() };
}

function sendJson(response, status, body) {
  response.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  response.end(JSON.stringify(body));
}

async function readJson(request) {
  const chunks = [];
  let size = 0;

  for await (const chunk of request) {
    size += chunk.length;
    if (size > 16_384) {
      throw new Error("Request is too large");
    }
    chunks.push(chunk);
  }

  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

async function serveStatic(pathname, response) {
  const requestedPath = pathname === "/" ? "index.html" : pathname.slice(1);
  if (!["index.html", "app.js", "styles.css"].includes(requestedPath)) {
    response.writeHead(404).end();
    return;
  }

  const types = {
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".css": "text/css; charset=utf-8",
  };
  const contents = await readFile(join(publicDirectory, requestedPath));
  response.writeHead(200, {
    "content-type": types[extname(requestedPath)],
    "cache-control": "no-cache",
  });
  response.end(contents);
}

const server = createServer(async (request, response) => {
  try {
    const url = new URL(request.url, "http://localhost");

    if (request.method === "GET" && url.pathname === "/api/state") {
      sendJson(response, 200, state());
      return;
    }

    if (request.method === "GET" && url.pathname === "/health") {
      sendJson(response, 200, { status: "ok" });
      return;
    }

    if (request.method === "POST" && url.pathname === "/api/transactions") {
      const { child, minutes, comment, createdAt } = await readJson(request);
      const { valid, normalizedComment } = validateTransaction(minutes, comment);
      const normalizedTimestamp = normalizeTimestamp(createdAt, true);

      if (!children.includes(child) || !valid || !normalizedTimestamp) {
        sendJson(response, 400, { error: "Please provide a child, time, and short comment." });
        return;
      }

      const balance = Number(balanceStatement.get(child).minutes);
      if (minutes < 0 && balance + minutes < 0) {
        sendJson(response, 409, { error: `${child} does not have that much time available.` });
        return;
      }

      insertStatement.run(child, minutes, normalizedComment, normalizedTimestamp);
      sendJson(response, 201, state());
      return;
    }

    const transactionMatch = url.pathname.match(/^\/api\/transactions\/(\d+)$/);
    if (request.method === "PUT" && transactionMatch) {
      const transaction = transactionStatement.get(Number(transactionMatch[1]));
      if (!transaction) {
        sendJson(response, 404, { error: "That transaction no longer exists." });
        return;
      }

      const { minutes, comment, createdAt } = await readJson(request);
      const { valid, normalizedComment } = validateTransaction(minutes, comment);
      const normalizedTimestamp = normalizeTimestamp(createdAt);
      if (!valid || !normalizedTimestamp) {
        sendJson(response, 400, { error: "Please provide a time, date, and short comment." });
        return;
      }

      const balanceWithoutTransaction =
        Number(balanceStatement.get(transaction.child).minutes) - Number(transaction.minutes);
      if (minutes < 0 && balanceWithoutTransaction + minutes < 0) {
        sendJson(response, 409, {
          error: `${transaction.child} would not have that much time available.`,
        });
        return;
      }

      updateStatement.run(minutes, normalizedComment, normalizedTimestamp, transaction.id);
      sendJson(response, 200, state());
      return;
    }

    if (request.method === "DELETE" && transactionMatch) {
      const transaction = transactionStatement.get(Number(transactionMatch[1]));
      if (!transaction) {
        sendJson(response, 404, { error: "That transaction no longer exists." });
        return;
      }

      const balanceAfterDeletion =
        Number(balanceStatement.get(transaction.child).minutes) - Number(transaction.minutes);
      if (balanceAfterDeletion < 0) {
        sendJson(response, 409, {
          error: `Remove some of ${transaction.child}'s used time first.`,
        });
        return;
      }

      deleteStatement.run(transaction.id);
      sendJson(response, 200, state());
      return;
    }

    if (request.method === "GET") {
      await serveStatic(url.pathname, response);
      return;
    }

    response.writeHead(405, { allow: "GET, POST, PUT, DELETE" }).end();
  } catch (error) {
    if (error instanceof SyntaxError) {
      sendJson(response, 400, { error: "The request was not valid JSON." });
      return;
    }
    console.error(error);
    sendJson(response, 500, { error: "Something went wrong. Please try again." });
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`Screen Time Bank listening on port ${port}`);
});
