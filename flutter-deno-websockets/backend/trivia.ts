export type TriviaAnswer = [string, boolean];

export type Trivia = {
    question: string;
    answers: [
        TriviaAnswer,
        TriviaAnswer,
        TriviaAnswer,
        TriviaAnswer,
    ];
};

const trivia: Trivia[] = [{
    question: "what's 2+2?",
    answers: [
        ["4", true],
        ["2", false],
        ["9", false],
        ["2", false],
    ],
}, {
    question: "what's 4+4?",
    answers: [
        ["4", false],
        ["2", false],
        ["8", true],
        ["9", false],
    ],
}];

export class TriviaGenerator {
    private trivia: Trivia[] = trivia;
    private step: number = 0;

    next(): Trivia {
        this.step += 1;
        this.step %= trivia.length;
        return this.trivia[this.step];
    }
}
