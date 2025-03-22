import { assertUnreachable, fatal } from "./assert.ts";
import { BaseData, Battle } from "./battle.ts";

export class Fighter {
    public readonly id: number;
    private user: User;
    public available: boolean;

    constructor(id: number, user: User) {
        this.id = id;
        this.user = user;
        this.available = true;
    }

    name() {
        return this.user.name();
    }
    answer() {
        return this.user.answer();
    }
    connected(): boolean {
        return this.user.connected();
    }
    sendMessage(msg: Response) {
        this.user.sendMessage(msg);
    }
}

type Leaderboard = {
    [name: string]: number;
};

export class Arena {
    private idGen: number = 0;
    private pool: Fighter[] = [];
    private battles: Battle[] = [];
    private leaderboard: Leaderboard = {};

    private createId(): number {
        this.idGen += 1;
        return this.idGen;
    }

    connected(user: User) {
        this.pool.push(
            new Fighter(
                this.createId(),
                user,
            ),
        );
    }

    private checkForNewBattles() {
        const available = this.pool.filter((user) => user.available);
        if (available.length > 1) {
            for (let i = 0; i < available.length; i += 2) {
                if (i + 1 >= available.length) {
                    break;
                }
                const fighter_0 = available[i];
                const fighter_1 = available[i + 1];

                const battle = new Battle([fighter_0, fighter_1]);
                fighter_0.available = false;
                fighter_1.available = false;
                this.battles.push(battle);
            }
        }
    }

    private checkForFinishedBattles() {
        const finished = this.battles
            .filter((battle) => battle.result !== null);
        this.battles = this.battles
            .filter((battle) => battle.result === null);

        finished.forEach((_battle) => {
        });
    }

    step() {
        this.pool = this.pool.filter((fighter) => fighter.connected());
        this.checkForNewBattles();
    }
}

type Message =
    | { tag: "register"; name: string }
    | { tag: "answer"; answer: number };

export type BattleTriviaQuestion = {
    question: string;
    answers: readonly [string, string, string, string];
};

export type BattleResponse =
    | { tag: "idle"; you: BaseData; enemy: { name: string; base: BaseData } }
    | { tag: "question"; question: BattleTriviaQuestion; countdown: number }
    | { tag: "question_waiting_on_enemy"; countdown: number };

type ResponseErrorMessage =
    | "bad_input"
    | "double_register"
    | "empty_name"
    | "did_not_ask"
    | "double_answer";

export type Response =
    | { tag: "error"; message: ResponseErrorMessage }
    | { tag: "battle"; battle: BattleResponse }
    | { tag: "register_name" };

type UserState =
    | { tag: "none" }
    | { tag: "connected" }
    | { tag: "disconnected_after_connected" }
    | { tag: "registered"; name: string }
    | { tag: "disconnected_after_registered"; name: string };

export type UserAnswerState =
    | { tag: "none" }
    | { tag: "requested_answer" }
    | { tag: "answered"; answer: 0 | 1 | 2 | 3 };

function isValidAnswer(
    answer: number,
): answer is (UserAnswerState & { tag: "answered" })["answer"] {
    return answer >= 0 && answer <= 3;
}

export class User {
    private socket: WebSocket;

    private state: UserState;
    private arena: Arena;
    private answerState: UserAnswerState;

    constructor(socket: WebSocket, manager: Arena) {
        this.socket = socket;
        this.arena = manager;
        this.answerState = { tag: "none" };
        this.state = { tag: "none" };

        this.socket.addEventListener("open", () => this.socketOpened());
        this.socket.addEventListener("close", () => this.socketClosed());
        this.socket.addEventListener(
            "message",
            (event) => this.rawMessageReceived(event.data),
        );
    }

    requestAnswer() {
        if (this.answerState.tag !== "none") {
            return fatal("shouldn't be called after asking");
        }
        this.answerState = { tag: "requested_answer" };
    }

    receivedAnswer() {
        if (this.answerState.tag !== "requested_answer") {
            return fatal("shouldn't be called after asking");
        }
        this.answerState = { tag: "requested_answer" };
    }

    answer(): UserAnswerState & { tag: "requested_answer" | "answered" } {
        if (this.answerState.tag === "none") {
            return fatal("shouldn't be called before asking");
        }
        return this.answerState;
    }

    name(): string {
        switch (this.state.tag) {
            case "none":
            case "connected":
            case "disconnected_after_connected":
                return fatal("should never be called before being registered");
            case "registered":
            case "disconnected_after_registered":
                return this.state.name;
            default:
                assertUnreachable(this.state);
        }
    }

    connected(): boolean {
        switch (this.state.tag) {
            case "none":
            case "connected":
            case "disconnected_after_connected":
                return fatal("should never be called before being registered");
            case "registered":
                return true;
            case "disconnected_after_registered":
                return false;
            default:
                assertUnreachable(this.state);
        }
    }

    private rawMessageReceived(message: string) {
        try {
            this.messageReceived(JSON.parse(message));
        } catch {
            this.sendMessage({ tag: "error", message: "bad_input" });
        }
    }

    sendMessage(message: Response) {
        this.socket.send(JSON.stringify(message));
    }

    private socketOpened() {
        this.state = { tag: "connected" };
        this.sendMessage({ tag: "register_name" });
    }
    private socketRegistered(name: string) {
        this.state = { tag: "registered", name };
        this.arena.connected(this);
    }

    private socketClosed() {
        switch (this.state.tag) {
            case "none":
                return fatal("cannot disconnect without connecting");
            case "connected":
                this.state = {
                    tag: "disconnected_after_connected",
                };
                break;
            case "registered":
                this.state = {
                    tag: "disconnected_after_registered",
                    name: this.state.name,
                };
                break;
            case "disconnected_after_connected":
            case "disconnected_after_registered":
                return fatal("cannot double disconnect");
            default:
                assertUnreachable(this.state);
        }
    }

    private messageReceived(message: Message) {
        switch (message.tag) {
            case "answer":
                switch (this.answerState.tag) {
                    case "none":
                        return this.sendMessage({
                            tag: "error",
                            message: "did_not_ask",
                        });
                    case "answered":
                        return this.sendMessage({
                            tag: "error",
                            message: "double_answer",
                        });
                    case "requested_answer":
                        if (!isValidAnswer(message.answer)) {
                            return this.sendMessage({
                                tag: "error",
                                message: "bad_input",
                            });
                        }
                        this.answerState = {
                            tag: "answered",
                            answer: message.answer,
                        };
                }
                break;
            case "register": {
                if (this.state.tag !== "connected") {
                    return this.sendMessage({
                        tag: "error",
                        message: "double_register",
                    });
                }
                if (message.name.trim() === "") {
                    return this.sendMessage({
                        tag: "error",
                        message: "empty_name",
                    });
                }
                this.socketRegistered(message.name);
            }
        }
    }
}
