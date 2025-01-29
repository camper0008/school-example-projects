import { Db, id, Visit } from "./db.ts";
import { Database } from "@db/sqlite";

export class SqliteDb implements Db {
    private constructor(connection: Database) {
        this.connection = connection;
    }

    private connection: Database;

    public static connect(path: string): SqliteDb {
        const db = new Database(path);
        db.prepare(
            "CREATE TABLE IF NOT EXISTS clicks (id TEXT PRIMARY KEY, date TEXT)",
        ).run();

        return new SqliteDb(db);
    }

    public createVisit(date: string): null {
        this.connection.prepare(
            "INSERT INTO clicks(id, date) VALUES(?, ?)",
        ).run(id(), date);

        return null;
    }

    public visits(): Visit[] {
        const visits = this.connection.prepare(
            "SELECT * from clicks",
        ).all<Visit>();
        return visits;
    }
}
