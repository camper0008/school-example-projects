import { Db, User, uuid } from "./db.ts";
import { Database } from "@db/sqlite";
import { HashedPassword } from "./hashed_password.ts";

export class SqliteDb implements Db {
    private constructor(connection: Database) {
        this.connection = connection;
    }

    private connection: Database;

    public static connect(path: string): SqliteDb {
        const db = new Database(path);
        db.prepare(
            "CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, username TEXT, password TEXT, animal TEXT)",
        ).run();

        return new SqliteDb(db);
    }

    public createUser(
        username: string,
        password: HashedPassword,
        animal: string,
    ): null {
        this.connection.prepare(
            "INSERT INTO users(id, username, password, animal) VALUES(?, ?, ?, ?)",
        ).run(uuid(), username, password.value, animal);
        return null;
    }
    public userFromName(username: string): User | null {
        const user = this.connection.prepare(
            "SELECT * from users WHERE username=?",
        ).get<User>(username);
        return user ?? null;
    }
    public userFromId(id: string): User | null {
        const user = this.connection.prepare(
            "SELECT * from users WHERE id=?",
        ).get<User>(id);
        return user ?? null;
    }
}
