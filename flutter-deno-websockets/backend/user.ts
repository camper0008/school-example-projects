import { Hook } from "./event.ts";
import { iter } from "./itertools.ts";

export type UserId = number;

export class Guts {
    readonly id: UserId;
    readonly manager: UserManager;
    readonly socket: WebSocket;

    constructor(manager: UserManager, socket: WebSocket) {
        this.id = manager.newId();
        this.manager = manager;
        this.socket = socket;
    }
}

export class UserManager {
    private interval: number;
    private idCount: number;
    private unopened: UnopenedUser[];
    private unregistered: UnregisteredUser[];
    private registered: RegisteredUser[];

    constructor() {
        this.idCount = 0;
        this.unopened = [];
        this.unregistered = [];
        this.registered = [];
        this.interval = setInterval(() => this.step(), 1000);
    }

    private users() {
        return [
            this.unopened,
            this.unregistered,
            this.registered,
        ] as const;
    }

    private step() {
    }

    newId(): UserId {
        this.idCount += 1;
        return this.idCount;
    }

    userConnected(socket: WebSocket) {
        const guts = new Guts(this, socket);
        this.unopened.push(new UnopenedUser(guts));
    }

    userOpened(user: UnopenedUser) {
        this.purge(user.id());
        const guts = user.dispose();
        this.unregistered.push(new UnregisteredUser(guts));
    }

    userRegistered(user: UnregisteredUser, name: string) {
        this.purge(user.id());
        const guts = user.dispose();
        this.registered.push(new RegisteredUser(name, guts));
    }

    private purge(id: UserId) {
        this.users().forEach((users) => {
            const found = users.find((user) => user.id() === id);
            if (!found) return;
            found.dispose();
            iter<AnyUser>(users)
                .filterInPlace((user) => found.id() !== user.id());
        });
    }

    userClosed<R, S>(user: User<R, S>) {
        this.purge(user.id());
    }

    dispose() {
        clearInterval(this.interval);
        this.users().flat().forEach((user) => user.dispose());
    }
}

type ErrorResponse = {
    tag: "error";
    message: string;
};

type AnyUser = User<unknown, unknown>;

export abstract class User<
    Receive,
    Send,
> {
    private guts: Guts;
    private hook: Hook;

    constructor(guts: Guts) {
        this.guts = guts;
        this.hook = new Hook(this.guts.socket);
        this.hook.connected(() => this.opened());
        this.hook.disconnected(() => this.closed());
        this.hook.messaged((event) => {
            try {
                const data = JSON.parse(event.data);
                if (typeof data !== "object") {
                    return this.send({ tag: "error", message: "invalid data" });
                }
                this.received(data);
            } catch {
                this.send({ tag: "error", message: "invalid data" });
            }
        });
    }

    id() {
        return this.guts.id;
    }

    protected manager() {
        return this.guts.manager;
    }

    send(message: Send | ErrorResponse): void {
        this.guts.socket.send(JSON.stringify(message));
    }

    protected opened(): void {}

    protected received(_message: Receive): void {}

    protected closed(): void {
        this.guts.manager.userClosed(this);
    }

    dispose(): Guts {
        this.hook.dispose();
        return this.guts;
    }
}

class UnopenedUser extends User<void, void> {
    constructor(guts: Guts) {
        super(guts);
    }
    override opened(): void {
        this.manager().userOpened(this);
    }
}

type UnregisteredUserReceive = { tag: "register"; name: string };
type UnregisteredUserSend = { tag: "register_name" };

class UnregisteredUser
    extends User<UnregisteredUserReceive, UnregisteredUserSend> {
    constructor(guts: Guts) {
        super(guts);
        this.send({ tag: "register_name" });
    }
    override received(message: UnregisteredUserReceive): void {
        if (message.tag !== "register" || typeof message.name !== "string") {
            return;
        }
        this.manager().userRegistered(this, message.name);
    }
}

class RegisteredUser extends User<void, void> {
    public readonly name: string;

    constructor(name: string, guts: Guts) {
        super(guts);
        this.name = name;
    }
}
