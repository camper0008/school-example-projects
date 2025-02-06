import { makeId } from "./make_id.ts";
import { Sessions, Token } from "./sessions.ts";

export class MemSessions implements Sessions {
  private sessions: {
    userId: string;
    token: Token;
  }[] = [];

  createSession(userId: string): Token {
    const token: Token = {
      inner: makeId(),
    };
    this.sessions.push({ userId, token });
    return token;
  }
  userIdFromToken(token: Token): string | null {
    const session = this.sessions.find((t) => t.token.inner === token.inner);
    if (session === undefined) {
      return null;
    }
    return session.userId;
  }
}
