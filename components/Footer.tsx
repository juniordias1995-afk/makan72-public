"use client";

import Link from "next/link";
import { Github, Mail, Heart, Crown } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";

export default function Footer() {
  const { lang } = useLanguage();

  const content = {
    PT: {
      description: "O sistema operacional que transforma você no CEO da sua equipa de agentes IA.",
      links: "Links",
      social: "Social",
      what: "O que é",
      features: "Funcionalidades",
      how: "Como Funciona",
      why: "Porquê",
      newsletter: "Newsletter do CEO",
      newsletterPlaceholder: "seu@email.com",
      subscribe: "Subscrever",
      copyright: "© 2026 Makan72. Todos os direitos reservados.",
      madeWith: "Feito para CEOs como você",
    },
    EN: {
      description: "The operating system that transforms you into the CEO of your AI agent team.",
      links: "Links",
      social: "Social",
      what: "What is",
      features: "Features",
      how: "How it Works",
      why: "Why",
      newsletter: "CEO Newsletter",
      newsletterPlaceholder: "you@email.com",
      subscribe: "Subscribe",
      copyright: "© 2026 Makan72. All rights reserved.",
      madeWith: "Made for CEOs like you",
    },
  };

  const t = content[lang];

  const socialLinks = [
    { icon: Github, href: "https://github.com/juniordias1995-afk/makan72-public", label: "GitHub" },
    { icon: Mail, href: "mailto:hello@makan72.com", label: "Email" },
  ];

  return (
    <footer className="relative border-t border-border/30 bg-bg-surface/30">
      {/* Background */}
      <div className="absolute inset-0 grid-pattern opacity-[0.02]" />
      <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[500px] h-[250px] bg-gradient-to-t from-primary/5 to-transparent rounded-full blur-3xl" />

      <div className="relative z-10 container-tight py-14">
        <div className="grid gap-10 lg:grid-cols-4">
          {/* Brand */}
          <div className="lg:col-span-2">
            <Link href="/" className="inline-flex items-center gap-3 group">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl border border-primary/20 bg-primary/10">
                <span className="text-lg font-bold text-primary">M</span>
              </div>
              <span className="text-xl font-display font-bold text-gradient">
                Makan72
              </span>
            </Link>
            <p className="mt-3 max-w-md text-body text-text-secondary">
              {t.description}
            </p>
            
            {/* Social */}
            <div className="mt-5 flex gap-2">
              {socialLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex h-9 w-9 items-center justify-center rounded-lg border border-border/50 text-text-secondary transition-all hover:border-primary/30 hover:text-primary hover:bg-primary/5"
                  aria-label={link.label}
                >
                  <link.icon className="h-4 w-4" />
                </a>
              ))}
            </div>
          </div>

          {/* Links */}
          <div>
            <h4 className="text-sm font-display font-semibold text-text-primary mb-3 uppercase tracking-wider">{t.links}</h4>
            <ul className="space-y-2">
              <li>
                <Link href="/sobre" className="text-body text-text-secondary hover:text-primary transition-colors underline-animation">
                  {t.what}
                </Link>
              </li>
              <li>
                <Link href="/funcionalidades" className="text-body text-text-secondary hover:text-primary transition-colors underline-animation">
                  {t.features}
                </Link>
              </li>
              <li>
                <Link href="/como-funciona" className="text-body text-text-secondary hover:text-primary transition-colors underline-animation">
                  {t.how}
                </Link>
              </li>
              <li>
                <Link href="/porque-makan72" className="text-body text-text-secondary hover:text-primary transition-colors underline-animation">
                  {t.why}
                </Link>
              </li>
            </ul>
          </div>

          {/* Newsletter - Coming Soon */}
          <div>
            <h4 className="text-sm font-display font-semibold text-text-primary mb-3 flex items-center gap-2 uppercase tracking-wider">
              <Crown className="h-3 w-3 text-primary" />
              {t.newsletter}
            </h4>
            <p className="text-sm text-text-secondary">
              {lang === "PT" ? "Em breve!" : "Coming soon!"}
            </p>
          </div>
        </div>

        {/* Bottom */}
        <div className="mt-10 border-t border-border/30 pt-6">
          <div className="flex flex-col items-center justify-between gap-3 sm:flex-row">
            <p className="text-caption text-text-muted">{t.copyright}</p>
            <p className="flex items-center gap-2 text-caption text-text-muted">
              {t.madeWith}
              <Heart className="h-3 w-3 text-primary animate-pulse" />
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
}
