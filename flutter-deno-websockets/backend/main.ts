import { Arena, User } from "./arena.ts";

function main() {
    const battle = new Arena();
    Deno.serve((req) => {
        if (req.headers.get("upgrade") != "websocket") {
            return new Response(null, { status: 501 });
        }
        const { socket, response } = Deno.upgradeWebSocket(req);
        new User(socket, battle);
        return response;
    });
}

if (import.meta.main) {
    main();
}
