// I HATE THE JAVASCRIPT EVENT API

type OpenCloseFunctor = () => void;
type MessageFunctor = (event: MessageEvent) => void;

export class Hook {
    private socket: WebSocket;
    private connect: OpenCloseFunctor[];
    private disconnect: OpenCloseFunctor[];
    private message: MessageFunctor[];

    constructor(socket: WebSocket) {
        this.socket = socket;
        this.connect = [];
        this.disconnect = [];
        this.message = [];
    }

    connected(listener: OpenCloseFunctor) {
        this.socket.addEventListener("open", listener);
        this.connect.push(listener);
    }

    messaged(listener: MessageFunctor) {
        this.socket.addEventListener("message", listener);
        this.message.push(listener);
    }

    disconnected(listener: OpenCloseFunctor) {
        this.socket.addEventListener("close", listener);
        this.disconnect.push(listener);
    }

    dispose() {
        this.connect
            .forEach((f) => this.socket.removeEventListener("open", f));

        this.disconnect
            .forEach((f) => this.socket.removeEventListener("close", f));

        this.message
            .forEach((f) => this.socket.removeEventListener("message", f));
    }
}
