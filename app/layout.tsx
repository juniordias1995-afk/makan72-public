import type { Metadata } from "next";
import { Inter, Space_Grotesk } from "next/font/google";
import "./globals.css";
import { LanguageProvider } from "@/context/LanguageContext";
import { ThemeProvider } from "@/context/ThemeContext";
import ScrollProgress from "@/components/ScrollProgress";
import BackToTop from "@/components/BackToTop";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

const spaceGrotesk = Space_Grotesk({
  subsets: ["latin"],
  variable: "--font-space-grotesk",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://makan72.com"),
  title: "Makan72 — Sistema Operacional para Agentes IA",
  description: "Seus agentes IA esquecem tudo entre sessões. O Makan72 não. Memória permanente. Disciplina absoluta. Qualquer modelo IA.",
  keywords: ["IA", "Agentes AI", "Automação", "Sistema Operacional", "Makan72"],
  authors: [{ name: "Makan72 Team" }],
  creator: "Makan72 Team",
  publisher: "Makan72",
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  openGraph: {
    title: "Makan72 — Sistema Operacional para Agentes IA",
    description: "Seus agentes IA esquecem tudo entre sessões. O Makan72 não. Memória permanente. Disciplina absoluta. Qualquer modelo IA.",
    type: "website",
    url: "https://makan72.com",
    siteName: "Makan72",
    images: [
      {
        url: "/opengraph-image.png",
        width: 1200,
        height: 630,
        alt: "Makan72 — Sistema Operacional para Agentes IA",
      },
    ],
    locale: "pt_BR",
  },
  twitter: {
    card: "summary_large_image",
    title: "Makan72 — Sistema Operacional para Agentes IA",
    description: "Seus agentes IA esquecem tudo entre sessões. O Makan72 não.",
    images: ["/twitter-image.png"],
    creator: "@makan72",
    site: "@makan72",
  },
  icons: {
    icon: [
      { url: "/favicon.svg", type: "image/svg+xml" },
      { url: "/favicon-32x32.png", sizes: "32x32", type: "image/png" },
      { url: "/favicon-16x16.png", sizes: "16x16", type: "image/png" },
    ],
    apple: [
      { url: "/apple-touch-icon.png", sizes: "180x180", type: "image/png" },
    ],
    other: [
      {
        rel: "mask-icon",
        url: "/favicon.svg",
        color: "#00A3B0",
      },
    ],
  },
  manifest: "/site.webmanifest",
  alternates: {
    canonical: "https://makan72.com",
  },
  verification: {
    // Google Search Console, Bing, etc. can be added here
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR" suppressHydrationWarning>
      <body className={`${inter.variable} ${spaceGrotesk.variable} font-sans bg-bg-main text-text-primary`}>
        <ThemeProvider>
          <LanguageProvider>
            <ScrollProgress color="gradient" height="md" showPercentage={true} />
            {children}
            <BackToTop threshold={300} position="bottom-right" showScrollPercentage={true} />
          </LanguageProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
