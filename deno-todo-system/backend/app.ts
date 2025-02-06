import { Application, Router } from "@oak/oak";
import * as controller from "./controllers.ts";
import { Db } from "./db.ts";
import { SqliteDb } from "./sqlite_db.ts";
import { Sessions } from "./sessions.ts";
import { MemSessions } from "./mem_sessions.ts";
import { oakCors } from "cors";

export function runApp({ port }: { port: number }) {
  const router = new Router();
  const db: Db = new SqliteDb();
  const sessions: Sessions = new MemSessions();

  router.post("/register", async (ctx) => {
    const body = await ctx.request.body.json();
    if (!body.username || !body.password) {
      ctx.response.body = { ok: false, error: "invalid body" };
      return;
    }
    ctx.response.body = await controller.register(
      { username: body.username, password: body.password },
      db,
    );
  });
  router.post("/login", async (ctx) => {
    const body = await ctx.request.body.json();
    if (!body.username || !body.password) {
      ctx.response.body = { ok: false, error: "invalid body" };
      return;
    }
    ctx.response.body = await controller.login(
      { username: body.username, password: body.password },
      db,
      sessions,
    );
  });
  router.post("/create_todo", async (ctx) => {
    const body = await ctx.request.body.json();
    if (!body.token || !body.text) {
      ctx.response.body = { ok: false, error: "invalid body" };
      return;
    }
    ctx.response.body = controller.createTodo(
      { token: body.token, text: body.text },
      db,
      sessions,
    );
  });
  router.post("/delete_todo", async (ctx) => {
    const body = await ctx.request.body.json();
    if (!body.token || !body.todoId) {
      ctx.response.body = { ok: false, error: "invalid body" };
      return;
    }
    ctx.response.body = controller.deleteTodo(
      { token: body.token, todoId: body.todoId },
      db,
      sessions,
    );
  });
  router.post("/edit_todo", async (ctx) => {
    const body = await ctx.request.body.json();
    if (!body.token || !body.todoId || !body.text) {
      ctx.response.body = { ok: false, error: "invalid body" };
      return;
    }
    ctx.response.body = controller.editTodo(
      { token: body.token, todoId: body.todoId, text: body.text },
      db,
      sessions,
    );
  });
  router.post("/todos", async (ctx) => {
    const body = await ctx.request.body.json();
    if (!body.token) {
      ctx.response.body = { ok: false, error: "invalid body" };
      return;
    }
    ctx.response.body = controller.todos(
      { token: body.token },
      db,
      sessions,
    );
  });

  const app = new Application();
  app.use(router.routes());
  app.use(router.allowedMethods());
  app.use(oakCors());

  app.addEventListener("listen", (event) => {
    console.log(`listening at http://localhost:${event.port}`);
  });

  app.listen({ port });
}
