import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  site: "https://gamepad-mouse.dev",
  vite: {
    plugins: [tailwindcss()],
  },
});
