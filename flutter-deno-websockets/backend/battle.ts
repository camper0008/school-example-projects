import { assertUnreachable } from "./assert.ts";
import { iter } from "./itertools.ts";
import * as trivia from "./trivia.ts";
import { Guts, User, UserId } from "./user.ts";

const names = [
    "Mikkel",
    "From",
    "Teis",
    "Theis",
    "Pieter",
    "Phami",
    "Mads",
    "Kasper",
    "Chris",
];

function randInt(min: number, max: number): number {
    return Math.floor((max - min) * Math.random()) + min;
}

class Soldier {
    private name: string;
    public health: number;
    public readonly damage: number;

    constructor(health: number, damage: number) {
        this.name = names[Math.floor(Math.random() * names.length)];
        this.health = health;
        this.damage = damage;
    }

    data(): SoldierData {
        return {
            name: this.name,
            health: this.health,
            damage: this.damage,
        } as const;
    }
}

class Base {
    private health: number = 10;
    private soldiers: Soldier[] = [];

    alive(): boolean {
        return this.health > 0;
    }

    damage(): number {
        return this.soldiers.at(0)?.damage ?? 0;
    }

    private cullDead() {
        const first = this.soldiers.at(0);
        if (!first) {
            return;
        }
        if (first.health > 0) {
            return;
        }
        this.soldiers.unshift();
    }

    addSoldier(health: number, damage: number) {
        this.soldiers.push(new Soldier(health, damage));
    }

    step(other: Base) {
        this.cullDead();
        const damage = other.damage();
        const first = this.soldiers.at(0);
        if (first) {
            first.health -= damage;
        } else {
            this.health -= damage;
        }
    }

    data(): BaseData {
        return {
            health: this.health,
            soldiers: this.soldiers.map((soldier) => soldier.data()),
        } as const;
    }
}

export type SoldierData = {
    name: string;
    health: number;
    damage: number;
};

export type BaseData = {
    health: number;
    soldiers: SoldierData[];
};

type Question = {
    trivia: trivia.Trivia;
    soldier: {
        health: number;
        damage: number;
    };
};

type BattleStateQuestionAsked = {
    tag: "question_asked";
    question: Question;
    answers: [null | 0 | 1 | 2 | 3, null | 0 | 1 | 2 | 3];
    countdown: number;
};
type BattleStateIdle = { tag: "idle"; countdown: number };
type BattleStateDone = { tag: "done"; winner: UserId; loser: UserId };

type BattleState =
    | BattleStateQuestionAsked
    | BattleStateIdle
    | BattleStateDone;

type AnswerState =
    | { tag: "none" }
    | { tag: "requested_answer" }
    | { tag: "answered"; answer: 0 | 1 | 2 | 3 };

type TriviaPops = {
    question: string;
    answers: readonly [string, string, string, string];
};

type BattleUserReceive = { tag: "answer"; answer: number };

type BattleUserSendInner =
    | {
        tag: "idle";
        you: BaseData;
        enemy: { name: string; base: BaseData };
        countdown: number;
    }
    | { tag: "trivia"; trivia: TriviaPops; countdown: number }
    | { tag: "trivia_waiting_on_enemy"; countdown: number };

type BattleUserSend = { tag: "battle"; battle: BattleUserSendInner };

export class BattleUser extends User<BattleUserReceive, BattleUserSend> {
    readonly name: string;
    readonly base: Base;
    private answerState: AnswerState;

    constructor(name: string, guts: Guts) {
        super(guts);
        this.name = name;
        this.base = new Base();
        this.answerState = { tag: "none" };
    }

    requestAnswer(): void {
        if (this.answerState.tag !== "none") {
            throw new Error(
                "unreachable: should never be called before resetting",
            );
        }
    }

    answer(): 0 | 1 | 2 | 3 | null {
        if (this.answerState.tag === "none") {
            throw new Error(
                "unreachable: should never be called before requesting answer",
            );
        }
        if (this.answerState.tag === "requested_answer") {
            return null;
        }
        return this.answerState.answer;
    }

    resetAnswer(): void {
        this.answerState = { tag: "none" };
    }
}

export class Battle {
    private state: BattleState;
    private triviaGenerator: trivia.TriviaGenerator;
    private users: [BattleUser, BattleUser];

    constructor(fighters: [BattleUser, BattleUser]) {
        this.state = { tag: "idle", countdown: 10 };
        this.triviaGenerator = new trivia.TriviaGenerator();
        this.users = fighters;
    }

    private other(fighter: BattleUser): BattleUser {
        if (this.users[0].id() === fighter.id()) {
            return this.users[1];
        }
        if (this.users[1].id() === fighter.id()) {
            return this.users[0];
        }
        throw new Error("unreachable, should be either or");
    }

    private questionAnswered(state: BattleStateQuestionAsked): void {
        const { trivia, soldier } = state.question;

        iter(state.answers)
            .filterMap((answer, user) => {
                if (answer === null || !trivia.answers[answer].correct) {
                    return null;
                }
                return user;
            }).forEach((user) => {
                this.users[user].base.addSoldier(
                    soldier.health,
                    soldier.damage,
                );
            });

        this.state = { tag: "idle", countdown: 5 };
        this.users.forEach((user) => user.resetAnswer());
    }

    private stepQuestionAsked(
        state: BattleStateQuestionAsked,
    ): void {
        this.users.forEach((user, idx) => {
            state.answers[idx] = user.answer();
        });

        const timeoutReached = state.countdown <= 0;
        const everybodyAnswered = state.answers
            .every((answer) => answer !== null);

        if (timeoutReached || everybodyAnswered) {
            return this.questionAnswered(state);
        }
    }

    private askQuestion(_state: BattleStateIdle) {
        this.state = {
            tag: "question_asked",
            countdown: 60,
            question: {
                trivia: this.triviaGenerator.next(),
                soldier: {
                    health: randInt(1, 8),
                    damage: randInt(1, 3),
                },
            },
            answers: [null, null],
        };
        this.users.forEach((user) => user.requestAnswer());
    }

    private stepIdle(state: BattleStateIdle): void {
        if (state.countdown <= 0) {
            this.askQuestion(state);
            return;
        }
        const loser = this.users.find(({ base }) => !base.alive());
        if (loser === undefined) {
            return;
        }
        const winner = this.other(loser);
        this.state = {
            tag: "done",
            winner: winner.id(),
            loser: loser.id(),
        };
    }

    result(): { winner: UserId; loser: UserId } | null {
        if (this.state.tag !== "done") {
            return null;
        }
        return this.state;
    }

    disconnectHappened(id: UserId) {
        if (this.state.tag === "done") return;
        const loser = this.users.find((user) => user.id() === id);
        if (loser === undefined) {
            return;
        }
        const winner = this.other(loser);
        this.state = {
            tag: "done",
            winner: winner.id(),
            loser: loser.id(),
        };
    }

    step() {
        if (this.state.tag === "done") return;
        this.logic();
        this.render();
    }

    private logic() {
        if (this.state.tag === "done") return;
        switch (this.state.tag) {
            case "question_asked":
                return this.stepQuestionAsked(this.state);
            case "idle":
                return this.stepIdle(this.state);
            default:
                assertUnreachable(this.state);
        }
    }

    private renderQuestionAsked(state: BattleStateQuestionAsked) {
        function respond(
            state: BattleStateQuestionAsked,
            me: BattleUser,
        ) {
            const hasAnswered = me.answer() !== null;
            if (hasAnswered) {
                me.send({
                    tag: "battle",
                    battle: {
                        tag: "trivia_waiting_on_enemy",
                        countdown: state.countdown,
                    },
                });
                return;
            }
            const trivia = state.question.trivia;
            const battle = {
                tag: "trivia",
                countdown: state.countdown,
                trivia: {
                    question: trivia.question,
                    answers: [
                        trivia.answers[0].content,
                        trivia.answers[1].content,
                        trivia.answers[2].content,
                        trivia.answers[3].content,
                    ],
                },
            } as const;
            me.send({
                tag: "battle",
                battle,
            });
        }

        this.users.forEach((me) => respond(state, me));
    }

    private renderIdle(state: BattleStateIdle) {
        function respond(
            state: BattleStateIdle,
            me: BattleUser,
            enemy: BattleUser,
        ) {
            me.send({
                tag: "battle",
                battle: {
                    tag: "idle",
                    you: me.base.data(),
                    enemy: {
                        name: enemy.name,
                        base: enemy.base.data(),
                    },
                    countdown: state.countdown,
                },
            });
        }

        this.users.forEach((me, idx) => {
            const enemy = idx === 0 ? this.users[1] : this.users[0];
            respond(state, me, enemy);
        });
    }

    private render() {
        if (this.state.tag === "done") return;
        switch (this.state.tag) {
            case "question_asked":
                return this.renderQuestionAsked(this.state);
            case "idle":
                return this.renderIdle(this.state);
            default:
                assertUnreachable(this.state);
        }
    }
}
