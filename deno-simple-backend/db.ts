export interface Visit {
    id: string;
    date: string;
}

export function id() {
    const id = crypto.randomUUID();
    return id;
}

export interface Db {
    createVisit(date: string): null;
    visits(): Visit[];
}
