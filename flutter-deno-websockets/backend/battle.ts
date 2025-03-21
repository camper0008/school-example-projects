import { fatal } from "./assert.ts";
import { User } from "./sockets.ts";
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

type Fighter = {
    socket: User;
    base: Base;
};

type BattleResult =
    | { tag: "firstWon" }
    | { tag: "secondWon" }
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
    private fighters: [Fighter, Fighter];

    constructor(fighters: [User, User]) {
        this.state = { tag: "idle", countdown: 10 };
        this.triviaGenerator = new TriviaGenerator();
        this.fighters = [
            { socket: fighters[0], base: new Base() },
            { socket: fighters[1], base: new Base() },
        ];
    }

    private askQuestion(state: BattleStateIdle) {
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

    private questionAnswered(state: BattleStateQuestionAsked) {
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
    }

    private stepQuestionAsked(
        state: BattleStateQuestionAsked,
    ) {
        this.fighters.forEach((fighter, i) => {
            const answer = fighter.socket.answer();
            if (answer.tag === "requested_answer") {
                return;
            }
            state.question.answers[i] = answer.answer;
        });

        const timeoutReached = state.countdown <= 0;
        const everybodyAnswered = state.question.answers
            .every((answer) => answer !== null);

        if (timeoutReached || everybodyAnswered) {
            this.questionAnswered(state);
        }
    }

    private stepIdle(state: BattleStateIdle): BattleResult | null {
        if (state.countdown <= 0) {
            this.askQuestion(state);
            return null;
        }
        const base = [
            this.fighters[0].base,
            this.fighters[1].base,
        ] as const;

        base[0].step(base[1]);
        base[1].step(base[0]);

        const anyDead = base.some((b) => !b.alive());
        if (anyDead) {
            const anyAlive = base.some((b) => b.alive());
            if (!anyAlive) {
                return { tag: "tie" };
            } else if (base[0].alive()) {
                return { tag: "firstWon" };
            } else if (base[1].alive()) {
                return { tag: "secondWon" };
            } else {
                fatal("unreachable");
            }
        }
        return null;
    }

    private step(): BattleResult | null {
        this.state.countdown -= 1;
        switch (this.state.tag) {
            case "question_asked": {
                this.stepQuestionAsked(this.state);
                return null;
            }
            case "idle": {
                return this.stepIdle(this.state);
            }
        }
    }

    async start(): Promise<BattleResult> {
        while (true) {
            const result = this.step();
            if (!result) {
                await wait(1);
                continue;
            }
            return result;
        }
    }
}
