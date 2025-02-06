import * as sqlite from "@db/sqlite";
import { Db, Todo, User } from "./db.ts";
import { makeId } from "./make_id.ts";

export class SqliteDb implements Db {
  private connection: sqlite.Database;

  constructor() {
    this.connection = new sqlite.Database("todo.db");
    this.connection.prepare(
      "CREATE TABLE IF NOT EXISTS user (id TEXT PRIMARY KEY, username TEXT, password TEXT)",
    ).run();

    this.connection.prepare(
      "CREATE TABLE IF NOT EXISTS todo (id TEXT PRIMARY KEY, owner TEXT, text TEXT)",
    ).run();
  }

  userFromUsername(username: string): User | null {
    const user = this.connection.prepare("SELECT * FROM users WHERE username=?")
      .get<
        User
      >(username);
    if (user === undefined) {
      return null;
    }
    return user;
  }

  createUser(username: string, password: string): void {
    this.connection.prepare("INSERT INTO user(id, username, password)").run(
      makeId(),
      username,
      password,
    );
  }
  createTodo(owner: string, text: string): Todo {
    const id = makeId();

    this.connection.prepare("INSERT INTO todo(id, owner, text)").run(
      id,
      owner,
      text,
    );

    return { id, owner, text };
  }
  todoFromId(todoId: string): Todo | null {
    const todo = this.connection.prepare("SELECT * FROM todo WHERE id=?").get<
      Todo
    >(todoId);
    if (todo === undefined) {
      return null;
    }
    return todo;
  }
  deleteTodo(todoId: string): void {
    this.connection.prepare("DELETE FROM todo WHERE id=?").run(todoId);
  }
  todosFromOwner(owner: string): Todo[] {
    return this.connection.prepare("SELECT * FROM todo WHERE owner=?").all<
      Todo
    >(
      owner,
    );
  }
  editTodo(todoId: string, text: string): void {
    this.connection.prepare("UPDATE todo SET text=? WHERE id=?").run(
      text,
      todoId,
    );
  }
}
