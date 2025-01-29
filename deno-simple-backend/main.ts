import { Application, Router } from "@oak/oak";
import { Db, Visit } from "./db.ts";
import { SqliteDb } from "./sqlite.ts";

function visit(db: Db): string {
    const now = new Date();
    db.createVisit(now.toISOString());
    const visits = db.visits();
    const count = visits.reduce((acc, _) => acc + 1, 0);
    return `This site has been visited ${count} time${count === 1 ? "" : "s"}!`;
}

function visits(db: Db): Visit[] {
    const visits = db.visits();
    return visits;
}

async function main() {
    const db = SqliteDb.connect("./visits.db");
    const router = new Router();

    router.get("/", (ctx) => {
        const response = visit(db);
        ctx.response.body = response;
    });

    router.get("/visits", (ctx) => {
        const response = visits(db);
        ctx.response.body = response;
    });

    const app = new Application();
    app.use(router.routes());
    app.use(router.allowedMethods());

    app.addEventListener(
        "listen",
        ({ port }) =>
            console.log(`Server listening on http://localhost:${port}`),
    );

    await app.listen();
}

if (import.meta.main) {
    main();
}
