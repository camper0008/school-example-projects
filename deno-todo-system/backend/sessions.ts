export type Token = {
  inner: string;
};

export interface Sessions {
  createSession(userId: string): Token;
  userIdFromToken(token: Token): string | null;
}
