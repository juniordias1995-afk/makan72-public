"use client";

import Link from "next/link";
import { Sun, Moon, Menu, X, Github } from "lucide-react";
import { useState, useEffect } from "react";
import { useLanguage } from "@/context/LanguageContext";
import { useTheme } from "@/context/ThemeContext";

export default function Navbar() {
  const { lang, setLang } = useLanguage();
  const { theme, toggleTheme } = useTheme();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const navItems = {
    PT: [
      { href: "/sobre", label: "O que é" },
      { href: "/funcionalidades", label: "Funcionalidades" },
      { href: "/como-funciona", label: "Como Funciona" },
      { href: "/porque-makan72", label: "Porquê" },
    ],
    EN: [
      { href: "/sobre", label: "What is" },
      { href: "/funcionalidades", label: "Features" },
      { href: "/como-funciona", label: "How it Works" },
      { href: "/porque-makan72", label: "Why" },
    ],
  };

  const t = navItems[lang];

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        scrolled ? "py-2" : "py-4"
      }`}
    >
      <div className="container-tight">
        <div
          className={`flex items-center justify-between rounded-xl px-5 py-2.5 transition-all duration-500 ${
            scrolled ? "glass-strong shadow-elevated" : "bg-transparent"
          }`}
        >
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="relative">
              <div className="absolute inset-0 rounded-lg bg-primary/20 blur-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              <div className="relative flex h-8 w-8 items-center justify-center rounded-lg border border-primary/20 bg-primary/10">
                <span className="text-base font-bold text-primary">M</span>
              </div>
            </div>
            <div className="flex flex-col">
              <span className="text-base font-display font-bold text-gradient">
                Makan72
              </span>
              <span className="hidden text-[10px] text-text-tertiary sm:block tracking-wider uppercase">
                Sistema Operacional
              </span>
            </div>
          </Link>

          {/* Desktop Navigation */}
          <ul className="hidden md:flex items-center gap-1">
            {t.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className="relative px-3 py-2 text-sm font-medium text-text-secondary transition-colors hover:text-primary underline-animation"
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>

          {/* Right side */}
          <div className="flex items-center gap-2">
            {/* GitHub */}
            <Link
              href="https://github.com/juniordias1995-afk/makan72-public"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:flex h-8 w-8 items-center justify-center rounded-lg border border-border/50 text-text-secondary transition-all hover:border-primary/30 hover:text-primary hover:bg-primary/5"
            >
              <Github className="h-4 w-4" />
            </Link>

            {/* Language Toggle */}
            <div className="hidden sm:flex items-center rounded-lg border border-border/50 bg-bg-main/50 p-0.5">
              <button
                onClick={() => setLang('PT')}
                className={`rounded-md px-2.5 py-1 text-xs font-medium transition-all ${
                  lang === 'PT'
                    ? 'bg-primary text-white'
                    : 'text-text-secondary hover:text-primary'
                }`}
              >
                PT
              </button>
              <button
                onClick={() => setLang('EN')}
                className={`rounded-md px-2.5 py-1 text-xs font-medium transition-all ${
                  lang === 'EN'
                    ? 'bg-primary text-white'
                    : 'text-text-secondary hover:text-primary'
                }`}
              >
                EN
              </button>
            </div>

            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="group relative h-8 w-8 rounded-lg border border-border/50 flex items-center justify-center text-text-secondary transition-all hover:border-primary/30 hover:text-primary hover:bg-primary/5"
            >
              {theme === 'light' ? (
                <Moon className="h-4 w-4 transition-transform group-hover:rotate-12" />
              ) : (
                <Sun className="h-4 w-4 transition-transform group-hover:rotate-45" />
              )}
            </button>

            {/* Mobile Menu Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-border/50 text-text-secondary transition-all hover:border-primary/30 hover:text-primary md:hidden"
              aria-expanded={mobileMenuOpen}
              aria-controls="mobile-menu"
              aria-label={mobileMenuOpen ? "Fechar menu" : "Abrir menu"}
            >
              {mobileMenuOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu */}
      <div
        id="mobile-menu"
        aria-hidden={!mobileMenuOpen}
        className={`fixed inset-x-4 top-16 z-50 rounded-xl glass-strong shadow-elevated transition-all duration-300 md:hidden ${
          mobileMenuOpen
            ? "opacity-100 translate-y-0"
            : "opacity-0 -translate-y-4 pointer-events-none"
        }`}
      >
        <div className="p-4">
          <ul className="space-y-1">
            {t.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className="block rounded-lg px-4 py-2.5 text-body text-text-secondary transition-colors hover:bg-primary/5 hover:text-primary"
                  onClick={() => setMobileMenuOpen(false)}
                  tabIndex={mobileMenuOpen ? 0 : -1}
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
          
          <div className="mt-4 flex items-center justify-between border-t border-border/30 pt-4">
            <div className="flex items-center gap-1 rounded-lg border border-border/50 p-0.5">
              <button
                onClick={() => setLang('PT')}
                className={`rounded-md px-2.5 py-1 text-xs font-medium transition-all ${
                  lang === 'PT' ? 'bg-primary text-white' : 'text-text-secondary'
                }`}
                tabIndex={mobileMenuOpen ? 0 : -1}
              >
                PT
              </button>
              <button
                onClick={() => setLang('EN')}
                className={`rounded-md px-2.5 py-1 text-xs font-medium transition-all ${
                  lang === 'EN' ? 'bg-primary text-white' : 'text-text-secondary'
                }`}
                tabIndex={mobileMenuOpen ? 0 : -1}
              >
                EN
              </button>
            </div>
            
            <Link
              href="https://github.com/juniordias1995-afk/makan72-public"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 rounded-lg border border-primary/30 px-3 py-1.5 text-sm font-medium text-primary"
              tabIndex={mobileMenuOpen ? 0 : -1}
            >
              <Github className="h-4 w-4" />
              GitHub
            </Link>
          </div>
        </div>
      </div>
    </nav>
  );
}
