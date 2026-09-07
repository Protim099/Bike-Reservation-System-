import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        ink: "#12213A",       // deep transit-navy, headers & primary text
        concrete: "#EDEDE8",  // page background, like pavement
        panel: "#F7F7F4",     // slightly lighter surface
        charcoal: "#1B1B1B",  // body text
        signal: "#F2A93B",    // amber — primary actions, "go" signal
        route: "#2F6E5B",     // route-green — available / success
        hazard: "#B3412C",    // brick-red — errors / cancelled
        lane: "#C9C9BE",      // dashed lane-marker grey
      },
      fontFamily: {
        display: ["var(--font-display)"],
        body: ["var(--font-body)"],
      },
      backgroundImage: {
        "lane-dash":
          "repeating-linear-gradient(90deg, #C9C9BE 0 14px, transparent 14px 26px)",
      },
    },
  },
  plugins: [],
};
export default config;
