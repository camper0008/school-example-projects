import { Battle, FightingUser } from "./battle.ts";
import { iter } from "./itertools.ts";
import { Guts, User, UserId } from "./user.ts";

type Leaderboard = { [name: RegisteredUser["name"]]: number };

export class UserManager {
    private interval: number;
    private idCount: number;
    private unconnected: UnconnectedUser[];
    private unregistered: UnregisteredUser[];
    private registered: RegisteredUser[];
    private fighting: FightingUser[];
    private battles: Battle[];
    private disconnected: UserId[];
    private leaderboard: Leaderboard;

    constructor() {
        this.idCount = 0;
        this.unconnected = [];
        this.unregistered = [];
        this.registered = [];
        this.fighting = [];
        this.battles = [];
        this.disconnected = [];
        this.leaderboard = {};
        this.interval = setInterval(() => this.step(), 1000);
    }

    private users() {
        return [
            this.unconnected,
            this.unregistered,
            this.registered,
            this.fighting,
        ] as const;
    }

    private notifyBattlesOfDisconnect() {
        this.disconnected.forEach((id) =>
            this.battles.forEach((battle) => battle.disconnectHappened(id))
        );
    }
    private battleStep() {
        this.battles.forEach((battle) => battle.step());
    }
    private evaluateFinishedBattles() {
        iter(this.battles)
            .extractMap((battle) => battle.result())
            .forEach(({ winner: winnerId, loser: loserId }) => {
                const fighters = iter(this.fighting)
                    .extract((user) =>
                        user.id() === winnerId || user.id() === loserId
                    ).toList();
                if (fighters.length !== 2) {
                    throw new Error(
                        `expected length of 2, got ${fighters.length}`,
                    );
                }
                const winner = fighters
                    .find((user) => user.id() === winnerId);
                const loser = fighters
                    .find((user) => user.id() === loserId);

                if (winner === undefined || loser === undefined) {
                    throw new Error("somehow purged prematurely");
                }

                const winnerScore = this.leaderboard[winner.name] ?? 0;
                const loserScore = this.leaderboard[loser.name] ?? 0;

                this.leaderboard[winner.name] = winnerScore + 1;
                this.leaderboard[loser.name] = loserScore - 1;

                const winnerGuts = winner.dispose();
                const loserGuts = loser.dispose();

                this.registered.push(
                    new RegisteredUser(winner.name, winnerGuts),
                    new RegisteredUser(loser.name, loserGuts),
                );
            });
    }

    private startNewBattles() {
        function toFightingUser(user: RegisteredUser): FightingUser {
            const guts = user.dispose();
            return new FightingUser(user.name, guts);
        }
        if (this.registered.length < 2) {
            return;
        }
        const length = this.registered.length;
        const candidates = iter(this.registered)
            .extract((_, i) => {
                if (i % 2 !== 0) {
                    return true;
                }
                return i + 1 < length;
            })
            .toList();
        for (let i = 0; i < candidates.length; i += 2) {
            const left = toFightingUser(candidates[i]);
            const right = toFightingUser(candidates[i + 1]);
            this.fighting.push(left, right);
            this.battles.push(new Battle([left, right]));
        }
    }

    private sendLeaderboard() {
        const users = [
            ...this.registered.map((v) => `${v.name} (waiting)`),
            ...this.fighting.map((v) => `${v.name} (fighting)`),
        ];
        this.registered
            .forEach((user) =>
                user.send({
                    tag: "leaderboard",
                    leaderboard: this.leaderboard,
                    you: user.name,
                    users: users,
                })
            );
    }

    private step() {
        this.battleStep();
        this.notifyBattlesOfDisconnect();
        this.evaluateFinishedBattles();
        this.purgeDisconnected();
        this.startNewBattles();
        this.sendLeaderboard();
    }

    private purgeDisconnected() {
        while (true) {
            const user = this.disconnected.pop();
            if (user === undefined) break;
            this.purge(user);
        }
    }

    newId(): UserId {
        this.idCount += 1;
        return this.idCount;
    }

    socketCreated(socket: WebSocket) {
        const guts = new Guts(this, socket);
        this.unconnected.push(new UnconnectedUser(guts));
    }

    userOpened(user: UnconnectedUser) {
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

    userDisconnected<R, S>(user: User<R, S>) {
        this.disconnected.push(user.id());
    }

    dispose() {
        clearInterval(this.interval);
        this.users().flat().forEach((user) => user.dispose());
    }
}

type AnyUser = User<unknown, unknown>;

class UnconnectedUser extends User<void, void> {
    constructor(guts: Guts) {
        super(guts);
    }
    override connected(): void {
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

type RegisteredUserSend = {
    tag: "leaderboard";
    leaderboard: Leaderboard;
    you: string;
    users: string[];
};

class RegisteredUser extends User<void, RegisteredUserSend> {
    public readonly name: string;

    constructor(name: string, guts: Guts) {
        super(guts);
        this.name = name;
    }
}
