import { Hook } from "./event.ts";
import { UserManager } from "./user_manager.ts";

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

export type UserId = number;

type ErrorResponse = {
    tag: "error";
    message: string;
};

export abstract class User<
    Receive,
    Send,
> {
    private guts: Guts;
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

    id() {
        return this.guts.id;
    }

    protected manager() {
        return this.guts.manager;
    }

    send(message: Send | ErrorResponse): void {
        this.guts.socket.send(JSON.stringify(message));
    }

    protected connected(): void {}

    protected received(_message: Receive): void {}

    protected disconnected(): void {
        this.guts.manager.userDisconnected(this);
    }

    dispose(): Guts {
        this.hook.dispose();
        return this.guts;
    }
}
