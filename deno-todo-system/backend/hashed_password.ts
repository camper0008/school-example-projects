import * as bcrypt from "@felix/bcrypt";

type VerifyInput = {
  unhashed: string;
  hashed: string;
};

export class HashedPassword {
  public readonly value: string;
  private constructor(password: string) {
    this.value = password;
  }
  static async hash(password: string): Promise<HashedPassword> {
    const hashedPassword = await bcrypt.hash(password);
    return new HashedPassword(hashedPassword);
  }
  static async verify({ unhashed, hashed }: VerifyInput): Promise<boolean> {
    return await bcrypt.verify(unhashed, hashed);
  }
}
