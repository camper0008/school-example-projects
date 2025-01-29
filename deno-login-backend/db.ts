import { HashedPassword } from "./hashed_password.ts";

export interface User {
    id: string;
    name: string;
    password: string;
    animal: string;
}

export function uuid() {
    const id = crypto.randomUUID();
    return id;
}

export interface Token {
    user: User["id"];
    value: string;
}

export function token(user: User["id"]): Token {
    return {
        user,
        value: uuid(),
    };
}

export interface Db {
    createUser(
        username: string,
        password: HashedPassword,
        animal: string,
    ): null;
    userFromId(id: string): User | null;
    userFromName(username: string): User | null;
}
