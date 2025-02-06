import { runApp } from "./app.ts";

function main() {
  runApp({ port: 1234 });
}

if (import.meta.main) {
  main();
}
