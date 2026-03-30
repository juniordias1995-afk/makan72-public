"use client";

import { CloudUpload, Cpu, Rocket } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";

export default function HowItWorks() {
  const { lang } = useLanguage();

  const content = {
    PT: {
      title: "Três Passos. Resultados Infinitos.",
      subtitle: "Sem curva de aprendizagem. Sem configuração complexa. Comece a comandar em minutos.",
      steps: [
        {
          icon: CloudUpload,
          title: "Connect",
          desc: "Liga qualquer agente IA ao sistema em minutos. Sem código. Sem complicação.",
          color: "primary",
        },
        {
          icon: Cpu,
          title: "Enhance",
          desc: "O sistema injeta memória colectiva, contexto e disciplina operacional. Instantaneamente.",
          color: "accent",
        },
        {
          icon: Rocket,
          title: "Execute",
          desc: "Agentes alinhados executam com precisão e reportam resultados. Você apenas aprova.",
          color: "primary",
        },
      ],
    },
    EN: {
      title: "Three Steps. Infinite Results.",
      subtitle: "No learning curve. No complex configuration. Start commanding in minutes.",
      steps: [
        {
          icon: CloudUpload,
          title: "Connect",
          desc: "Connect any AI agent to the system in minutes. No code. No complication.",
          color: "primary",
        },
        {
          icon: Cpu,
          title: "Enhance",
          desc: "The system injects collective memory, context and operational discipline. Instantly.",
          color: "accent",
        },
        {
          icon: Rocket,
          title: "Execute",
          desc: "Aligned agents execute with precision and report results. You just approve.",
          color: "primary",
        },
      ],
    },
  };

  const t = content[lang];

  return (
    <section className="relative py-20 overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 bg-gradient-to-b from-bg-main via-bg-surface/30 to-bg-main" />
      <div className="absolute inset-0 grid-pattern opacity-[0.02]" />

      <div className="relative z-10 container-tight">
        {/* Header */}
        <div className="text-center mb-12">
          <h2 className="text-section text-text-primary">
            {t.title}
          </h2>
          <p className="mt-4 text-body-lg text-text-secondary max-w-xl mx-auto">
            {t.subtitle}
          </p>
        </div>

        {/* Steps */}
        <div className="grid gap-6 md:grid-cols-3">
          {t.steps.map((step, index) => (
            <div
              key={step.title}
              className="group relative"
            >
              {/* Glow */}
              <div className={`absolute -inset-0.5 rounded-2xl bg-gradient-to-r ${
                step.color === 'accent' ? 'from-accent to-primary' : 'from-primary to-accent'
              } opacity-0 blur transition duration-500 group-hover:opacity-20`} />
              
              {/* Card */}
              <div className="relative h-full rounded-2xl border border-border/50 bg-bg-surface/80 p-6 glass hover-lift">
                {/* Step number */}
                <div className={`absolute -top-3 left-6 flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold ${
                  step.color === 'accent' ? 'bg-accent text-white' : 'bg-primary text-white'
                }`}>
                  {index + 1}
                </div>

                {/* Icon */}
                <div className="mb-5 mt-1">
                  <div className={`inline-flex h-12 w-12 items-center justify-center rounded-xl border-2 transition-all duration-500 group-hover:scale-110 ${
                    step.color === 'accent'
                      ? 'border-accent/30 bg-accent/5 group-hover:border-accent/50'
                      : 'border-primary/30 bg-primary/5 group-hover:border-primary/50'
                  }`}>
                    <step.icon className={`h-6 w-6 ${step.color === 'accent' ? 'text-accent' : 'text-primary'}`} />
                  </div>
                </div>

                {/* Content */}
                <h3 className="text-xl font-display font-bold text-text-primary mb-2">
                  {step.title}
                </h3>
                <p className="text-body text-text-secondary">
                  {step.desc}
                </p>

                {/* Progress bar */}
                <div className="mt-5 h-1 w-full rounded-full bg-border/30 overflow-hidden">
                  <div 
                    className={`h-full rounded-full transition-all duration-1000 group-hover:w-full ${
                      step.color === 'accent' ? 'bg-accent' : 'bg-primary'
                    }`}
                    style={{ width: '0%' }}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
