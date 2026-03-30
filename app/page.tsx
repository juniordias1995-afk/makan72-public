"use client";

import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Footer from "@/components/Footer";
import FeatureCard from "@/components/FeatureCard";
import IntelligencePipeline from "@/components/IntelligencePipeline";
import HowItWorks from "@/components/HowItWorks";
import { Brain, Shield, Zap, RefreshCw, Lock, TrendingUp } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";

export default function Home() {
  const { lang } = useLanguage();

  const content = {
    PT: {
      featuresTitle: "Seja o CEO dos seus agentes IA",
      featuresSubtitle: "No Makan72, você comanda. Os agentes obedecem. Memória permanente. Disciplina absoluta.",
      features: [
        {
          icon: Brain,
          title: "Zero Repetição",
          desc: "O que um agente aprende, todos herdam. Erros acontecem uma vez — nunca duas."
        },
        {
          icon: RefreshCw,
          title: "Troca Instantânea",
          desc: "Claude hoje. Gemini amanhã. Troque de IA como quem troca de roupa — sem perder uma única memória."
        },
        {
          icon: Shield,
          title: "Disciplina Militar",
          desc: "Regras rígidas aplicadas a todos. Zero improvisação. Zero desculpas. Resultados garantidos."
        },
        {
          icon: Zap,
          title: "Escalabilidade Total",
          desc: "Comece sozinho. Termine com um exército de agentes. O Makan72 cresce com você."
        },
        {
          icon: Lock,
          title: "Privacidade Absoluta",
          desc: "Seus dados são seus. Memória local, criptografada e sob seu controlo total."
        },
        {
          icon: TrendingUp,
          title: "Evolução Contínua",
          desc: "Cada sessão torna o sistema mais inteligente. Aprendizado acumulativo automático."
        },
      ],
      ctaTitle: "Pronto para Comandar?",
      ctaSubtitle: "Junte-se aos CEOs que já não perdem tempo a repetir instruções.",
      ctaButton: "Começar Agora",
    },
    EN: {
      featuresTitle: "Be the CEO of Your AI Agents",
      featuresSubtitle: "With Makan72, you command. Agents obey. Permanent memory. Absolute discipline.",
      features: [
        {
          icon: Brain,
          title: "Zero Repetition",
          desc: "What one agent learns, all inherit. Errors happen once — never twice."
        },
        {
          icon: RefreshCw,
          title: "Instant Switch",
          desc: "Claude today. Gemini tomorrow. Switch AI like changing clothes — without losing a single memory."
        },
        {
          icon: Shield,
          title: "Military Discipline",
          desc: "Rigid rules applied to all. Zero improvisation. Zero excuses. Guaranteed results."
        },
        {
          icon: Zap,
          title: "Total Scalability",
          desc: "Start alone. End with an army of agents. Makan72 grows with you."
        },
        {
          icon: Lock,
          title: "Absolute Privacy",
          desc: "Your data is yours. Local, encrypted memory under your total control."
        },
        {
          icon: TrendingUp,
          title: "Continuous Evolution",
          desc: "Every session makes the system smarter. Automatic cumulative learning."
        },
      ],
      ctaTitle: "Ready to Command?",
      ctaSubtitle: "Join the CEOs who no longer waste time repeating instructions.",
      ctaButton: "Get Started",
    },
  };

  const t = content[lang];

  return (
    <main className="min-h-screen">
      <Navbar />
      <Hero />

      {/* Features Section */}
      <section className="relative py-20 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-bg-main via-bg-surface/30 to-bg-main" />
        <div className="absolute inset-0 grid-pattern opacity-[0.02]" />
        
        <div className="relative z-10 container-tight">
          <div className="text-center mb-12">
            <h2 className="text-section text-text-primary">
              {t.featuresTitle}
            </h2>
            <p className="mx-auto mt-4 max-w-2xl text-body-lg text-text-secondary">
              {t.featuresSubtitle}
            </p>
          </div>

          <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-3">
            {t.features.map((feature, index) => (
              <FeatureCard
                key={feature.title}
                icon={feature.icon}
                title={feature.title}
                description={feature.desc}
                delay={index * 100}
              />
            ))}
          </div>
        </div>
      </section>

      <IntelligencePipeline />

      <HowItWorks />

      {/* CTA Section */}
      <section className="relative py-20 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-bg-main via-bg-surface/50 to-bg-main" />
        <div className="absolute inset-0 grid-pattern opacity-[0.02]" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[300px] bg-gradient-to-r from-primary/10 via-accent/10 to-primary/10 rounded-full blur-3xl" />

        <div className="relative z-10 container-tight text-center">
          <div className="rounded-2xl border border-border/50 bg-bg-surface/80 p-10 glass">
            <h2 className="text-section text-text-primary">
              {t.ctaTitle}
            </h2>
            <p className="mt-3 text-body-lg text-text-secondary">
              {t.ctaSubtitle}
            </p>
            <div className="mt-6">
              <a
                href="https://github.com/juniordias1995-afk/makan72-public"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-full bg-primary px-6 py-3 text-base font-medium text-white shadow-card hover-lift magnetic-button"
              >
                {t.ctaButton}
              </a>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
