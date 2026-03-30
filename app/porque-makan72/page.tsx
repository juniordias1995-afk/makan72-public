"use client";

import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { TrendingUp, DollarSign, Clock, Crown } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";

export default function PorqueMakan72() {
  const { lang } = useLanguage();

  const content = {
    PT: {
      badge: "Você é o CEO",
      title: "Porquê o Makan72 é Diferente",
      subtitle: "Não é apenas mais um framework. É o sistema que coloca VOCÊ no comando.",
      tableTitle: "Comparativa: O Seu Poder",
      comparisons: [
        { feature: "Memória entre sessões", tradicional: "Cada sessão começa do zero. Zero aprendizado acumulado.", makan72: "Conhecimento eterno. O que aprendeu, fica. Para sempre." },
        { feature: "Troca de modelo IA", tradicional: "Reconfigurar tudo. Perder todo o contexto. Começar do zero.", makan72: "Troca instantânea. Memória preservada. Zero perda." },
        { feature: "Prevenção de erros", tradicional: "O mesmo erro repete-se. Infinitamente. Sem aprendizado.", makan72: "Erros registados. Nunca repetidos. Aprendizado garantido." },
        { feature: "Disciplina operacional", tradicional: "Depende de cada agente. Resultados inconsistentes.", makan72: "Regras rígidas aplicadas a todos. Resultados consistentes." },
        { feature: "Alinhamento com você", tradicional: "Instruções manuais repetidas. Sempre. Para sempre.", makan72: "Preferências aprendidas. Aplicadas automaticamente." },
        { feature: "Dependência de modelo", tradicional: "Locked-in num modelo. Preso a um fornecedor.", makan72: "Agnóstico. Use qualquer IA. A qualquer momento." },
        { feature: "Curva de aprendizagem", tradicional: "Alta. Cada agente aprende do zero. Tempo perdido.", makan72: "Zero. O sistema herda todo o contexto. Instantaneamente." },
      ],
      differentials: [
        { icon: TrendingUp, title: "Aprendizagem Contínua", desc: "Cada sessão torna o sistema mais inteligente. Erros nunca são repetidos. O conhecimento só cresce." },
        { icon: DollarSign, title: "Custo Zero de Lock-in", desc: "Não dependa de nenhum fornecedor. Troque de agente IA sem perder uma única memória. A liberdade é total." },
        { icon: Clock, title: "Economia Massiva de Tempo", desc: "Agentes novos já chegam sabendo tudo. Zero tempo perdido a repetir contexto. Você foca no que importa." },
      ],
      quote: "O Makan72 não é só um organizador. É um amplificador de poder. Qualquer IA fica extraordinária só por usar o sistema.",
      quoteAuthor: "CEO Boavidawork",
      cta: "Pronto para Ser o CEO?",
      ctaDesc: "Junte-se aos líderes que já não perdem tempo a repetir instruções. Comande. Obtenha resultados.",
      ctaButton: "Assuma o Comando",
    },
    EN: {
      badge: "You are the CEO",
      title: "Why Makan72 is Different",
      subtitle: "Not just another framework. The system that puts YOU in command.",
      tableTitle: "Comparison: Your Power",
      comparisons: [
        { feature: "Memory between sessions", tradicional: "Every session starts from zero. Zero accumulated learning.", makan72: "Eternal knowledge. What you learned, stays. Forever." },
        { feature: "AI model switch", tradicional: "Reconfigure everything. Lose all context. Start from zero.", makan72: "Instant switch. Memory preserved. Zero loss." },
        { feature: "Error prevention", tradicional: "Same error repeats. Infinitely. No learning.", makan72: "Errors logged. Never repeated. Guaranteed learning." },
        { feature: "Operational discipline", tradicional: "Depends on each agent. Inconsistent results.", makan72: "Rigid rules applied to all. Consistent results." },
        { feature: "Alignment with you", tradicional: "Manual instructions repeated. Always. Forever.", makan72: "Preferences learned. Applied automatically." },
        { feature: "Model dependency", tradicional: "Locked-in to one model. Trapped with one vendor.", makan72: "Agnostic. Use any AI. At any time." },
        { feature: "Learning curve", tradicional: "High. Each agent learns from zero. Time wasted.", makan72: "Zero. System inherits all context. Instantly." },
      ],
      differentials: [
        { icon: TrendingUp, title: "Continuous Learning", desc: "Every session makes the system smarter. Errors are never repeated. Knowledge only grows." },
        { icon: DollarSign, title: "Zero Lock-in Cost", desc: "Don't depend on any vendor. Switch AI agents without losing a single memory. Total freedom." },
        { icon: Clock, title: "Massive Time Savings", desc: "New agents already know everything. Zero time wasted repeating context. You focus on what matters." },
      ],
      quote: "Makan72 is not just an organizer. It's a power amplifier. Any AI becomes extraordinary just by using the system.",
      quoteAuthor: "CEO Boavidawork",
      cta: "Ready to Be the CEO?",
      ctaDesc: "Join the leaders who no longer waste time repeating instructions. Command. Get results.",
      ctaButton: "Take Command",
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
            <div className="mb-6 inline-flex">
              <span className="flex items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-4 py-2 text-sm font-medium text-primary">
                <Crown className="h-4 w-4" />
                {t.badge}
              </span>
            </div>
            <h1 className="font-display text-4xl font-bold md:text-6xl">{t.title}</h1>
            <p className="mx-auto mt-6 max-w-2xl text-xl text-text-secondary">{t.subtitle}</p>
          </div>
        </div>
      </section>

      {/* Comparison Cards */}
      <section className="py-20">
        <div className="mx-auto max-w-6xl px-6">
          <h2 className="font-display text-3xl font-bold text-center mb-12">{t.tableTitle}</h2>
          
          <div className="space-y-6">
            {t.comparisons.map((row, index) => (
              <div 
                key={row.feature} 
                className={`rounded-2xl border p-6 shadow-soft transition-all hover:shadow-card ${
                  index % 2 === 0 ? 'bg-bg-surface border-border' : 'bg-bg-main border-border/50'
                }`}
              >
                <div className="grid gap-6 md:grid-cols-3 md:items-center">
                  <div>
                    <p className="font-display text-lg font-bold text-text-primary">{row.feature}</p>
                  </div>
                  <div className="rounded-xl border border-border/50 bg-bg-main p-4">
                    <p className="text-sm text-text-muted mb-1">{lang === 'PT' ? 'Solução Tradicional' : 'Traditional Solution'}</p>
                    <p className="text-text-secondary">{row.tradicional}</p>
                  </div>
                  <div className="rounded-xl border border-primary/30 bg-primary/5 p-4">
                    <p className="text-sm text-primary mb-1">Makan72</p>
                    <p className="font-medium text-text-primary">{row.makan72}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Differentials */}
      <section className="border-t border-border bg-bg-surface py-24">
        <div className="mx-auto max-w-6xl px-6">
          <h2 className="font-display text-3xl font-bold text-center">{lang === 'PT' ? 'Diferenciais Chave' : 'Key Differentiators'}</h2>

          <div className="mt-16 grid gap-8 md:grid-cols-3">
            {t.differentials.map((item) => (
              <div key={item.title} className="group rounded-2xl border border-border bg-bg-main p-8 shadow-soft transition-all duration-300 hover:shadow-card-hover hover:-translate-y-1">
                <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full border border-primary bg-primary/10 transition-transform duration-300 group-hover:scale-110">
                  <item.icon className="h-8 w-8 text-primary" />
                </div>
                <h3 className="mt-6 font-display text-xl font-bold text-text-primary text-center">{item.title}</h3>
                <p className="mt-3 text-text-secondary text-center">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Quote */}
      <section className="py-24">
        <div className="mx-auto max-w-4xl px-6">
          <blockquote className="rounded-3xl border border-border bg-bg-surface p-12 text-center shadow-soft">
            <p className="font-display text-2xl font-medium text-text-primary italic">"{t.quote}"</p>
            <footer className="mt-6 text-text-secondary">— {t.quoteAuthor}</footer>
          </blockquote>
        </div>
      </section>

      {/* CTA */}
      <section className="border-t border-border bg-bg-surface py-24">
        <div className="mx-auto max-w-4xl px-6 text-center">
          <h2 className="font-display text-3xl font-bold md:text-4xl">{t.cta}</h2>
          <p className="mt-4 text-lg text-text-secondary">{t.ctaDesc}</p>
          <a
            href="https://github.com/juniordias1995-afk/makan72-public"
            target="_blank"
            rel="noopener noreferrer"
            className="mt-8 inline-block rounded-full border border-primary bg-primary px-8 py-4 text-lg font-medium text-white transition-all hover:shadow-card-hover hover:-translate-y-0.5"
          >
            {t.ctaButton}
          </a>
        </div>
      </section>

      <Footer />
    </main>
  );
}
