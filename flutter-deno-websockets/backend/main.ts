import { UserManager } from "./user.ts";

function main() {
    const man = new UserManager();
    Deno.serve((req) => {
        if (req.headers.get("upgrade") != "websocket") {
            return new Response(null, { status: 501 });
        }
        const { socket, response } = Deno.upgradeWebSocket(req);
        man.socketCreated(socket);
        return response;
    });
}

if (import.meta.main) {
    main();
}
