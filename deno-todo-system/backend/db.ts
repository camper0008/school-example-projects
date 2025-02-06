import { HashedPassword } from "./hashed_password.ts";

export type Todo = {
  id: string;
  owner: string;
  text: string;
};

export type User = {
  id: string;
  username: string;
  password: string;
};

export interface Db {
  userFromUsername(username: string): User | null;
  createUser(username: string, password: HashedPassword): void;
  createTodo(owner: string, text: string): Todo;
  todoFromId(todoId: string): Todo | null;
  deleteTodo(todoId: string): void;
  todosFromOwner(owner: string): Todo[];
  editTodo(todoId: string, text: string): void;
}
