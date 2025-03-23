import { Hook } from "./event.ts";

class Guts {
    id: number;
    manager: UserManager;
    socket: WebSocket;

    constructor(id: number, manager: UserManager, socket: WebSocket) {
        this.id = id;
        this.manager = manager;
        this.socket = socket;
    }
}

export class UserManager {
    private idGen: number;
    private unconnected: UnconnectedUser[];

    constructor() {
        this.idGen = 0;
        this.unconnected = [];
    }

    private idGen(): number {
        this.idGen += 1;
        return this.idGen;
    }

    registerSocket(socket: WebSocket) {
        const guts = new Guts(this.idGen, this, socket);
        const user = new UnconnectedUser(guts);
        this.unconnected.push(user);
    }
    registerConnected(user: UnconnectedUser) {}
    registerDisconnect(id: number) {}
}

type Tagged = {
    tag: string;
};

type ErrorResponse = {
    tag: "error";
    message: string;
};

abstract class Socket<
    Request extends Tagged,
    Response extends Tagged,
> {
    public readonly guts: Guts;
    private hook: Hook;

    constructor(guts: Guts) {
        this.guts = guts;
        this.hook = new Hook(this.guts.socket);
        this.hook.connected(() => this.connected());
        this.hook.disconnected(() => this.disconnected());
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

    send(message: Response | ErrorResponse): void {
        this.guts.socket.send(JSON.stringify(message));
    }

    connected(): void {}

    abstract received(message: Request): void;

    abstract disconnected(): void;

    dispose(): void {
        this.hook.dispose();
    }
}

type UnconnectedUserReq = { tag: "register"; name: string };
type UnconnectedUserRes = { tag: "register_name" };

class UnconnectedUser extends Socket<UnconnectedUserReq, UnconnectedUserRes> {
    constructor(guts: Guts) {
        super(guts);
    }
    override connected(): void {
        this.guts.manager.registerConnected(this);
    }
    disconnected(): void {
        throw new Error("Method not implemented.");
    }
    received(message: UnconnectedUserReq): void {
        throw new Error("Method not implemented.");
    }
}

class ConnectedUser extends Socket<UnconnectedUserReq, UnconnectedUserRes> {
    constructor(socket: WebSocket, manager: UserManager) {
        super(socket, manager);
    }
    override connected(): void {
        this.manager.registerUnconnected(this);
    }
    disconnected(): void {
        throw new Error("Method not implemented.");
    }
    received(message: UnconnectedUserReq): void {
        throw new Error("Method not implemented.");
    }
}
