type NonNullable<T> = T extends null | undefined ? never : T;

class ItertoolsExt<T> {
    private inner: T[];
    constructor(inner: T[]) {
        this.inner = inner;
    }

    extractMap<To extends NonNullable<S>, S>(
        predicate: (value: T, index: number) => To | null,
    ): ItertoolsExt<To> {
        const input = this.drain();
        const out: To[] = [];

        for (const [index, value] of input.entries()) {
            const mapped = predicate(value, index);
            if (mapped === null) {
                this.inner.push(value);
                continue;
            }
            out.push(mapped);
        }
        return iter(out);
    }

    drain(): ItertoolsExt<T> {
        return iter(this.inner.splice(0, this.inner.length));
    }

    entries() {
        return this.inner.entries();
    }

    extract(
        predicate: (value: T, index: number) => boolean,
    ): ItertoolsExt<T> {
        const input = this.drain();
        const out: T[] = [];

        for (const [index, value] of input.entries()) {
            if (!predicate(value, index)) {
                this.inner.push(value);
                continue;
            }
            out.push(value);
        }
        return iter(out);
    }

    filterInPlace(
        predicate: (value: T, index: number) => boolean,
    ): void {
        const input = this.drain();

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
