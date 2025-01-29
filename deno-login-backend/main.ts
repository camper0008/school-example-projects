import { Application, Router } from "@oak/oak";
import { SqliteDb } from "./sqlite.ts";
import { Db, Token, token } from "./db.ts";
import { err, ok, Result } from "@result/result";
import * as animals from "./animals.ts";
import { HashedPassword } from "./hashed_password.ts";
import { oakCors } from "cors";

interface RegisterRequest {
    username: string;
    password: string;
}

interface AnimalRequest {
    token: Token["value"];
}

interface LoginRequest {
    username: string;
    password: string;
}

function animal(
    db: Db,
    tokens: Token[],
    req: AnimalRequest,
): Result<string, string> {
    const token = tokens.find((v) => v.value === req.token);
    if (!token) {
        return err("Invalid token");
    }
    const user = db.userFromId(token.user);
    if (user === null) {
        return err("Invalid token");
    }
    return ok(user.animal);
}

async function register(
    db: Db,
    req: RegisterRequest,
): Promise<Result<void, string>> {
    const existingUser = db.userFromName(req.username);
    if (existingUser !== null) {
        return err("Username taken");
    }
    db.createUser(
        req.username,
        await HashedPassword.hash(req.password),
        animals.animal(),
    );
    return ok();
}
async function login(
    db: Db,
    req: LoginRequest,
): Promise<Result<Token, string>> {
    const existingUser = db.userFromName(req.username);
    if (existingUser === null) {
        return err("Invalid username or password");
    }
    const valid = await HashedPassword.verify({
        unhashed: req.password,
        hashed: existingUser.password,
    });
    if (!valid) {
        return err("Invalid username or password");
    }

    return ok(token(existingUser.id));
}

async function main() {
    const db = SqliteDb.connect("./login-example.db");
    const tokens: Token[] = [];
    const router = new Router();

    router.post("/register", async (ctx) => {
        const req: RegisterRequest = await ctx.request.body
            .json();
        if (!req.username || !req.password) {
            ctx.response.body = { ok: false, message: "Invalid request body" };
            return;
        }

        const res = (await register(db, req)).match(
            (_ok) => ({ ok: true, message: "Success" }),
            (err) => ({ ok: false, message: err }),
        );
        ctx.response.body = res;
    });

    router.post("/login", async (ctx) => {
        const req: LoginRequest = await ctx.request.body.json();
        if (!req.username || !req.password) {
            ctx.response.body = { ok: false, message: "Invalid request body" };
            return;
        }
        (await login(db, req)).match(
            (token) => {
                tokens.push(token);
                ctx.response.body = {
                    ok: true,
                    message: "Success",
                    token: token.value,
                };
            },
            (err) => ctx.response.body = { ok: false, message: err },
        );
    });

    router.post("/animal", async (ctx) => {
        const req: AnimalRequest = await ctx.request.body.json();
        if (!req.token) {
            ctx.response.body = { ok: false, message: "Invalid request body" };
            return;
        }
        const res = animal(db, tokens, req).match(
            (animal) => ({ ok: true, message: "success", animal }),
            (err) => ({ ok: false, message: err }),
        );
        ctx.response.body = res;
    });

    const app = new Application();
    app.use(oakCors());
    app.use(router.routes());
    app.use(router.allowedMethods());

    app.addEventListener(
        "listen",
        ({ port }) =>
            console.log(`Server listening on http://localhost:${port}`),
    );

    await app.listen({ port: 8080 });
}

if (import.meta.main) {
    main();
}
