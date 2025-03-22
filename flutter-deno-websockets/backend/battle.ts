import { Fighter } from "./arena.ts";
import { Trivia, TriviaGenerator } from "./trivia.ts";

type Question = {
    trivia: Trivia;
    soldier: {
        health: number;
        damage: number;
    };
    answers: [null | 0 | 1 | 2 | 3, null | 0 | 1 | 2 | 3];
};

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

type FighterExt = {
    fighter: Fighter;
    base: Base;
};

type BattleResult =
    | { tag: "done"; winner: Fighter["id"]; loser: Fighter["id"] }
    | { tag: "tie" };

async function wait(seconds: number): Promise<void> {
    return await new Promise((resolve) => {
        setTimeout(() => resolve(), seconds * 1000);
    });
}

type BattleStateQuestionAsked = {
    tag: "question_asked";
    question: Question;
    countdown: number;
};
type BattleStateIdle = { tag: "idle"; countdown: number };

type BattleState =
    | BattleStateQuestionAsked
    | BattleStateIdle;

export class Battle {
    private state: BattleState;
    private triviaGenerator: TriviaGenerator;
    private fighters: [FighterExt, FighterExt];
    public result: BattleResult | null;

    constructor(fighters: [Fighter, Fighter]) {
        this.result = null;
        this.state = { tag: "idle", countdown: 10 };
        this.triviaGenerator = new TriviaGenerator();
        this.fighters = [
            { fighter: fighters[0], base: new Base() },
            { fighter: fighters[1], base: new Base() },
        ];
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
                answers: [null, null],
            },
        };
    }

    private questionAnswered(state: BattleStateQuestionAsked): false {
        const correctAnswers = state.question.trivia.answers
            .map((answer, idx) => [idx, answer[1]] as const)
            .filter(([_idx, correct]) => correct)
            .map(([idx, _correct]) => idx);

        const answers = state.question.answers
            .map((v) => v !== null && correctAnswers.includes(v));

        const soldier = state.question.soldier;

        answers.forEach((correct, idx) => {
            if (!correct) {
                return;
            }
            this.fighters[idx].base.addSoldier(soldier.health, soldier.damage);
        });

        this.state = { tag: "idle", countdown: 5 };

        return false;
    }

    private stepQuestionAsked(
        state: BattleStateQuestionAsked,
    ): false {
        this.fighters.forEach((fighter, i) => {
            const answer = fighter.fighter.answer();
            if (answer.tag === "requested_answer") {
                return;
            }
            state.question.answers[i] = answer.answer;
        });

        const timeoutReached = state.countdown <= 0;
        const everybodyAnswered = state.question.answers
            .every((answer) => answer !== null);

        if (timeoutReached || everybodyAnswered) {
            return this.questionAnswered(state);
        }

        this.fighters.forEach(({ fighter }, i) => {
            const waitingOnEnemy = state.question.answers[i] !== null;

            const question = {
                question: state.question.trivia.question,
                answers: [
                    state.question.trivia.answers[0][0],
                    state.question.trivia.answers[1][0],
                    state.question.trivia.answers[2][0],
                    state.question.trivia.answers[3][0],
                ] as const,
            };

            const battle = waitingOnEnemy
                ? {
                    tag: "question_waiting_on_enemy" as const,
                }
                : {
                    tag: "question" as const,
                    question,
                };

            fighter.sendMessage({
                tag: "battle",
                battle: {
                    ...battle,
                    countdown: state.countdown,
                },
            });
        });
        return false;
    }

    private stepIdle(state: BattleStateIdle): boolean {
        if (state.countdown <= 0) {
            this.askQuestion(state);
            return false;
        }
        const base = [
            this.fighters[0].base,
            this.fighters[1].base,
        ] as const;

        base[0].step(base[1]);
        base[1].step(base[0]);

        const anyDead = base.some((b) => !b.alive());
        if (anyDead) {
            const allDead = base.every((b) => !b.alive());
            if (allDead) {
                this.result = { tag: "tie" };
            } else {
                const winner = base[0].alive() ? 0 : 1;
                const loser = base[0].alive() ? 1 : 0;
                this.result = {
                    tag: "done",
                    winner: this.fighters[winner].fighter.id,
                    loser: this.fighters[loser].fighter.id,
                };
            }
            return true;
        }

        this.fighters.forEach(({ fighter, base }, i) => {
            const enemy = i === 0 ? this.fighters[1] : this.fighters[0];
            fighter.sendMessage({
                tag: "battle",
                battle: {
                    tag: "idle",
                    you: base.data(),
                    enemy: {
                        name: enemy.fighter.name(),
                        base: enemy.base.data(),
                    },
                },
            });
        });

        return false;
    }

    private step(): boolean {
        const anyDisconnected = this.fighters
            .some(({ fighter }) => !fighter.connected());
        if (anyDisconnected) {
            const allDisconnected = this.fighters
                .every(({ fighter }) => !fighter.connected());
            if (allDisconnected) {
                this.result = { tag: "tie" };
            } else {
                const winner = this.fighters[0].fighter.connected() ? 0 : 1;
                const loser = this.fighters[0].fighter.connected() ? 1 : 0;
                this.result = {
                    tag: "done",
                    winner: this.fighters[winner].fighter.id,
                    loser: this.fighters[loser].fighter.id,
                };
            }
            return true;
        }
        this.state.countdown -= 1;
        switch (this.state.tag) {
            case "question_asked": {
                return this.stepQuestionAsked(this.state);
            }
            case "idle": {
                return this.stepIdle(this.state);
            }
        }
    }

    async start(): Promise<void> {
        while (true) {
            const fightOver = this.step();
            if (!fightOver) {
                await wait(1);
                continue;
            }
            return;
        }
    }
}
