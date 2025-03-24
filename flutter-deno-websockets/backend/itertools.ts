function drainReverse<T>(list: T[]): T[] {
    const result = [];
    while (true) {
        const v = list.pop();
        if (v === undefined) break;
        result.push(v);
    }
    return result;
}

function drain<T>(list: T[]): T[] {
    const v = drainReverse(list);
    v.reverse();
    return v;
}

type NonNullable<T> = T extends null | undefined ? never : T;

class ItertoolsExt<T> {
    private inner: T[];
    constructor(inner: T[]) {
        this.inner = inner;
    }

    filterInPlace(
        predicate: (value: T, index: number) => boolean,
    ): void {
        const input = drain(this.inner);

        for (const [index, value] of input.entries()) {
            if (!predicate(value, index)) continue;
            this.inner.push(value);
        }
    }

    filterMap<To extends NonNullable<S>, S>(
        predicate: (value: T, index: number) => To | null,
    ): ItertoolsExt<To> {
        const out = [];
        for (const [index, value] of this.inner.entries()) {
            const mapped = predicate(value, index);
            if (mapped === null) continue;
            out.push(mapped);
        }
        return iter(out);
    }

    forEach(fn: (value: T, index: number) => void): void {
        this.inner.forEach(fn);
    }

    toList(): T[] {
        return [...this.inner];
    }
}

export function iter<T>(inner: T[]): ItertoolsExt<T> {
    return new ItertoolsExt(inner);
}
