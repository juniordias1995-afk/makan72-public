"use client";

import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import HowItWorks from "@/components/HowItWorks";
import { useLanguage } from "@/context/LanguageContext";

export default function ComoFunciona() {
  const { lang } = useLanguage();

  const content = {
    PT: {
      title: "Três Passos. Resultados Infinitos.",
      subtitle: "Sem curva de aprendizagem. Sem configuração complexa. Comece a comandar em minutos.",
      pipelineTitle: "Como o Makan72 Potencializa o Seu Poder",
      steps: [
        { step: "Connect", desc: "Liga qualquer agente IA ao sistema em minutos. Sem código. Sem complicação." },
        { step: "Enhance", desc: "O sistema injeta memória colectiva, contexto e disciplina operacional. Instantaneamente." },
        { step: "Execute", desc: "Agentes alinhados executam com precisão e reportam resultados. Você apenas aprova." },
      ],
      startNow: "Pronto para Comandar?",
      startNowDesc: "O Makan72 está em desenvolvimento activo. Junte-se aos CEOs que já não perdem tempo.",
      startNowButton: "Ver Documentação",
    },
    EN: {
      title: "Three Steps. Infinite Results.",
      subtitle: "No learning curve. No complex configuration. Start commanding in minutes.",
      pipelineTitle: "How Makan72 Amplifies Your Power",
      steps: [
        { step: "Connect", desc: "Connect any AI agent to the system in minutes. No code. No complication." },
        { step: "Enhance", desc: "The system injects collective memory, context and operational discipline. Instantly." },
        { step: "Execute", desc: "Aligned agents execute with precision and report results. You just approve." },
      ],
      startNow: "Ready to Command?",
      startNowDesc: "Makan72 is in active development. Join the CEOs who no longer waste time.",
      startNowButton: "View Documentation",
    },
  };

  const t = content[lang];

  return (
    <main className="min-h-screen">
      <Navbar />
      <div className="pt-32" />

      <section className="py-20">
        <div className="mx-auto max-w-6xl px-6">
          <div className="text-center">
            <h1 className="font-display text-4xl font-bold md:text-6xl">{t.title}</h1>
            <p className="mx-auto mt-6 max-w-2xl text-xl text-text-secondary">{t.subtitle}</p>
          </div>
        </div>
      </section>

      <HowItWorks />

      <section className="border-t border-border bg-bg-surface py-24">
        <div className="mx-auto max-w-4xl px-6">
          <h2 className="font-display text-3xl font-bold text-center">{t.pipelineTitle}</h2>
          <div className="mt-12 space-y-8 text-center">
            {t.steps.map((step) => (
              <div key={step.step} className="rounded-2xl border border-border bg-bg-main p-8 shadow-soft">
                <p className="text-2xl font-bold text-primary">{step.step}</p>
                <p className="mt-2 text-lg text-text-secondary">{step.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-24">
        <div className="mx-auto max-w-4xl px-6">
          <div className="rounded-3xl border border-primary/30 bg-gradient-to-r from-primary/5 via-accent/5 to-primary/5 p-12 text-center shadow-soft">
            <h2 className="font-display text-3xl font-bold">{t.startNow}</h2>
            <p className="mt-4 text-lg text-text-secondary">{t.startNowDesc}</p>
            <a
              href="https://github.com/juniordias1995-afk/makan72-public"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-8 inline-block rounded-full border border-primary bg-primary px-8 py-4 text-lg font-medium text-white transition-all hover:shadow-card-hover hover:-translate-y-0.5"
            >
              {t.startNowButton}
            </a>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
