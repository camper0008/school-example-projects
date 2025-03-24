export type TriviaAnswer = { content: string; correct: boolean };

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
        { content: "4", correct: true },
        { content: "2", correct: false },
        { content: "9", correct: false },
        { content: "2", correct: false },
    ],
}, {
    question: "what's 4+4?",
    answers: [
        { content: "4", correct: false },
        { content: "2", correct: false },
        { content: "8", correct: true },
        { content: "9", correct: false },
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
