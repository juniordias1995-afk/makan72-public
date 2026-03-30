"use client";

import { ArrowRight, Cpu, Shield, Zap, Sparkles } from "lucide-react";
import Link from "next/link";
import { useLanguage } from "@/context/LanguageContext";

export default function Hero() {
  const { lang } = useLanguage();

  const content = {
    PT: {
      badge: "Você é o CEO. Seus agentes IA são a equipa.",
      title1: "Memória",
      title2: "Permanente",
      title3: "para Agentes IA",
      subtitle: "Seus agentes esquecem tudo entre sessões. O Makan72 não. Disciplina absoluta. Qualquer modelo IA.",
      cta1: "Assuma o Comando",
      cta2: "Ver Como Funciona",
      compatible: "Funciona com",
      features: [
        { icon: Shield, text: "Disciplina Absoluta" },
        { icon: Zap, text: "Qualquer Modelo IA" },
        { icon: Sparkles, text: "Memória Persistente" },
      ],
    },
    EN: {
      badge: "You are the CEO. Your AI agents are the team.",
      title1: "Permanent",
      title2: "Memory",
      title3: "for AI Agents",
      subtitle: "Your agents forget everything between sessions. Makan72 doesn't. Absolute discipline. Any AI model.",
      cta1: "Take Command",
      cta2: "See How It Works",
      compatible: "Works with",
      features: [
        { icon: Shield, text: "Absolute Discipline" },
        { icon: Zap, text: "Any AI Model" },
        { icon: Sparkles, text: "Persistent Memory" },
      ],
    },
  };

  const t = content[lang];

  return (
    <section className="relative flex min-h-[90vh] items-center justify-center overflow-hidden pt-20">
      {/* Aurora Background Effect */}
      <div className="aurora" aria-hidden="true">
        <div className="aurora-blob aurora-blob-1" />
        <div className="aurora-blob aurora-blob-2" />
        <div className="aurora-blob aurora-blob-3" />
      </div>
      
      {/* Grid Pattern */}
      <div className="absolute inset-0 grid-pattern opacity-[0.02]" aria-hidden="true" />
      
      {/* Particles */}
      <div className="particles" aria-hidden="true">
        <div className="particle top-[20%] left-[10%] delay-100" />
        <div className="particle top-[40%] left-[80%] delay-300" />
        <div className="particle top-[60%] left-[30%] delay-500" />
        <div className="particle top-[80%] left-[70%] delay-700" />
        <div className="particle top-[30%] left-[50%] delay-900" />
        <div className="particle top-[70%] left-[20%] delay-1100" />
      </div>

      {/* Content */}
      <div className="relative z-10 container-tight text-center">
        {/* Badge */}
        <div className="mb-8 animate-fade-in">
          <span className="inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/5 px-4 py-2 text-sm font-medium text-primary glass">
            <Cpu className="h-4 w-4" />
            {t.badge}
          </span>
        </div>

        {/* Icon */}
        <div className="mb-8 flex justify-center animate-fade-in-up delay-100">
          <div className="relative group">
            <div className="absolute inset-0 rounded-2xl bg-gradient-to-r from-primary to-accent opacity-20 blur-2xl animate-pulse-glow" />
            <div className="relative flex h-20 w-20 items-center justify-center rounded-2xl border border-primary/20 bg-bg-surface/80 glass shadow-card transition-all duration-500 group-hover:scale-110 group-hover:rotate-3">
              <Cpu className="h-10 w-10 text-primary transition-transform duration-500 group-hover:scale-125" />
            </div>
          </div>
        </div>

        {/* Title - Using text-hero class (48-60px) */}
        <h1 className="animate-fade-in-up delay-200 text-hero font-display">
          <span className="text-text-primary">{t.title1}</span>{" "}
          <span className="text-gradient-animated">{t.title2}</span>
          <br />
          <span className="text-text-secondary">{t.title3}</span>
        </h1>

        {/* Subtitle - Using text-body-lg (18px) */}
        <p className="mx-auto mt-6 max-w-2xl animate-fade-in-up delay-300 text-body-lg text-text-secondary font-medium">
          {t.subtitle}
        </p>

        {/* Feature badges */}
        <div className="mx-auto mt-8 max-w-xl animate-fade-in-up delay-400">
          <div className="flex flex-wrap justify-center gap-3">
            {t.features.map((feature, index) => (
              <div
                key={index}
                className="group flex items-center gap-2 rounded-full border border-border/50 bg-bg-surface/50 px-4 py-2 glass hover-lift"
              >
                <feature.icon className="h-4 w-4 text-primary transition-transform duration-300 group-hover:scale-110" />
                <span className="text-small text-text-secondary">{feature.text}</span>
              </div>
            ))}
          </div>
        </div>

        {/* CTAs */}
        <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row animate-fade-in-up delay-500">
          <Link
            href="/sobre"
            className="group relative overflow-hidden rounded-full bg-primary px-6 py-3 text-base font-medium text-white shadow-card hover-lift magnetic-button"
          >
            <span className="relative z-10 flex items-center gap-2">
              {t.cta1}
              <ArrowRight className="h-4 w-4 transition-transform duration-300 group-hover:translate-x-1" />
            </span>
            <span className="absolute inset-0 bg-gradient-to-r from-primary-light to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
          </Link>
          <Link
            href="/como-funciona"
            className="group rounded-full border border-border/50 bg-bg-surface/80 px-6 py-3 text-base font-medium text-text-primary glass hover-lift"
          >
            {t.cta2}
          </Link>
        </div>

        {/* Compatible with */}
        <div className="mt-16 animate-fade-in delay-700">
          <p className="text-caption text-text-muted mb-4 uppercase tracking-wider">{t.compatible}</p>
          <div className="flex flex-wrap justify-center gap-6">
            {["Claude", "Gemini", "Qwen", "Goose", "OpenCode"].map((name, index) => (
              <span
                key={name}
                className="text-base font-display font-semibold text-text-muted opacity-0 animate-fade-in transition-all duration-300 hover:text-primary hover:scale-110 cursor-default"
                style={{ animationDelay: `${800 + index * 100}ms`, animationFillMode: 'forwards' }}
              >
                {name}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* Scroll indicator */}
      <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce-subtle">
        <div className="h-10 w-px bg-gradient-to-b from-primary via-primary/50 to-transparent" />
      </div>
    </section>
  );
}
