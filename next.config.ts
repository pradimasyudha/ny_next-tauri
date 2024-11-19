import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  images: {
    unoptimized: true,
  },
  assetPrefix: "http://localhost:3000",
  distDir: "build",
};

export default nextConfig;
