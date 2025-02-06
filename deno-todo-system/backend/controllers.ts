import { hash, verify } from "@felix/bcrypt";
import { Sessions, Token } from "./sessions.ts";
import { Db, Todo } from "./db.ts";
import { Result } from "./result.ts";

type UserInput = {
  username: string;
  password: string;
};

export async function register(
  { username, password }: UserInput,
  db: Db,
): Promise<Result<null, string>> {
  const existingUser = db.userFromUsername(username);
  if (existingUser !== null) {
    return {
      ok: false,
      error: "username taken",
    };
  }
  const hashedPassword = await hash(password);
  db.createUser(username, hashedPassword);
  return {
    ok: true,
    value: null,
  };
}

export async function login(
  { username, password }: UserInput,
  db: Db,
  session: Sessions,
): Promise<Result<Token, string>> {
  const existingUser = db.userFromUsername(username);
  if (existingUser === null) {
    return { ok: false, error: "invalid username or password" };
  }
  const isValid = await verify(password, existingUser.password);
  if (!isValid) {
    return { ok: false, error: "invalid username or password" };
  }
  const token = session.createSession(existingUser.id);
  return { ok: true, value: token };
}

type CreateTodoInput = {
  token: Token;
  text: string;
};

export function createTodo(
  { token, text }: CreateTodoInput,
  db: Db,
  session: Sessions,
): Result<Todo, string> {
  const userId = session.userIdFromToken(token);
  if (userId === null) {
    return { ok: false, error: "invalid session" };
  }

  const todo = db.createTodo(userId, text);
  return { ok: true, value: todo };
}

type DeleteTodoInput = {
  todoId: string;
  token: Token;
};

export function deleteTodo(
  { token, todoId }: DeleteTodoInput,
  db: Db,
  session: Sessions,
): Result<null, string> {
  const userId = session.userIdFromToken(token);
  if (userId === null) {
    return { ok: false, error: "invalid session" };
  }

  const todo = db.todoFromId(todoId);
  if (todo === null) {
    return { ok: false, error: "invalid todo" };
  }

  if (userId !== todo.owner) {
    return { ok: false, error: "invalid todo" };
  }

  db.deleteTodo(todoId);

  return { ok: true, value: null };
}

export function todos(
  { token }: { token: Token },
  db: Db,
  session: Sessions,
): Result<Todo[], string> {
  const userId = session.userIdFromToken(token);
  if (userId === null) {
    return { ok: false, error: "invalid session" };
  }
  const todos = db.todosFromOwner(userId);
  return { ok: true, value: todos };
}

type EditTodoInput = {
  token: Token;
  todoId: string;
  text: string;
};

export function editTodo(
  { token, todoId, text }: EditTodoInput,
  db: Db,
  session: Sessions,
): Result<null, string> {
  const userId = session.userIdFromToken(token);
  if (!userId) {
    return { ok: false, error: "invalid session" };
  }

  const todo = db.todoFromId(todoId);
  if (todo === null) {
    return { ok: false, error: "invalid todo" };
  }
  if (todo.owner !== userId) {
    return { ok: false, error: "invalid todo" };
  }

  db.editTodo(todoId, text);
  return { ok: true, value: null };
}
