import { hash, verify } from "@felix/bcrypt";

interface Verify {
    unhashed: string;
    hashed: string;
}

export class HashedPassword {
    private constructor(hashedPassword: string) {
        this.value = hashedPassword;
    }
    public static async hash(password: string): Promise<HashedPassword> {
        return new HashedPassword(await hash(password));
    }
    public static async verify(
        { unhashed, hashed }: Verify,
    ): Promise<boolean> {
        return await verify(unhashed, hashed);
    }
    readonly value: string;
}
