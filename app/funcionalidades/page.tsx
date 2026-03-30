"use client";

import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import FeatureCard from "@/components/FeatureCard";
import { Brain, Network, Shield, Zap, FileText, GitBranch } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";

export default function Funcionalidades() {
  const { lang } = useLanguage();

  const content = {
    PT: {
      title: "O Seu Arsenal de Poder",
      subtitle: "Tudo o que precisa para comandar agentes IA como um verdadeiro CEO",
      features: [
        { 
          icon: Brain, 
          title: "Memória Colectiva", 
          desc: "Zero repetição. O que um agente aprende, todos herdam. Erros acontecem uma vez — nunca duas. O conhecimento é eterno." 
        },
        { 
          icon: Network, 
          title: "Agnóstico de IA", 
          desc: "Claude hoje. Gemini amanhã. Troque de IA como quem troca de roupa — sem perder uma única memória. A liberdade é total." 
        },
        { 
          icon: Shield, 
          title: "Disciplina Operacional", 
          desc: "Regras rígidas aplicadas a todos. Zero improvisação. Zero desculpas. Resultados consistentes, sessão após sessão." 
        },
        { 
          icon: Zap, 
          title: "Escalabilidade em 3 Fases", 
          desc: "Fase 1: Você comanda manualmente. Fase 2: Agentes comunicam entre si. Fase 3: Autonomia total. Você escolhe o ritmo." 
        },
        { 
          icon: FileText, 
          title: "Sistema de Correios", 
          desc: "Comunicação assíncrona via ficheiros. Cada agente tem caixa de correio própria. Notificações em tempo real. Nada se perde." 
        },
        { 
          icon: GitBranch, 
          title: "Controlo de Versão", 
          desc: "Todo o sistema versionado em git. Commits automáticos. Branch protegida. Você controla cada mudança." 
        },
      ],
      behind: "Tecnologias Simples, Poder Total",
      behindDesc: "O Makan72 é construído com ferramentas que resistem ao tempo:",
      techList: [
        { name: "Bash e Python", desc: "Automação robusta e scripts fiáveis" },
        { name: "YAML e JSON", desc: "Configuração legível e portátil" },
        { name: "Ficheiros Markdown", desc: "Memória persistente em formato humano" },
        { name: "Git", desc: "Histórico completo de todas as mudanças" },
      ],
      behindFooter: "Sem frameworks pesados. Sem dependências desnecessárias. Apenas código que funciona.",
    },
    EN: {
      title: "Your Arsenal of Power",
      subtitle: "Everything you need to command AI agents like a true CEO",
      features: [
        { 
          icon: Brain, 
          title: "Collective Memory", 
          desc: "Zero repetition. What one agent learns, all inherit. Errors happen once — never twice. Knowledge is eternal." 
        },
        { 
          icon: Network, 
          title: "AI Agnostic", 
          desc: "Claude today. Gemini tomorrow. Switch AI like changing clothes — without losing a single memory. Total freedom." 
        },
        { 
          icon: Shield, 
          title: "Operational Discipline", 
          desc: "Rigid rules applied to all. Zero improvisation. Zero excuses. Consistent results, session after session." 
        },
        { 
          icon: Zap, 
          title: "3-Phase Scalability", 
          desc: "Phase 1: You command manually. Phase 2: Agents communicate with each other. Phase 3: Full autonomy. You set the pace." 
        },
        { 
          icon: FileText, 
          title: "Mail System", 
          desc: "Asynchronous communication via files. Each agent has its own mailbox. Real-time notifications. Nothing is lost." 
        },
        { 
          icon: GitBranch, 
          title: "Version Control", 
          desc: "Entire system versioned in git. Automatic commits. Protected branch. You control every change." 
        },
      ],
      behind: "Simple Tech, Total Power",
      behindDesc: "Makan72 is built with tools that stand the test of time:",
      techList: [
        { name: "Bash and Python", desc: "Robust automation and reliable scripts" },
        { name: "YAML and JSON", desc: "Readable and portable configuration" },
        { name: "Markdown Files", desc: "Persistent memory in human format" },
        { name: "Git", desc: "Complete history of all changes" },
      ],
      behindFooter: "No heavy frameworks. No unnecessary dependencies. Just code that works.",
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

          <div className="mt-16 grid gap-8 md:grid-cols-2">
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

      <section className="border-t border-border bg-bg-surface py-24">
        <div className="mx-auto max-w-4xl px-6">
          <h2 className="font-display text-3xl font-bold text-center">{t.behind}</h2>
          <div className="mt-8 space-y-4 text-text-secondary">
            <p className="text-lg">{t.behindDesc}</p>
            <ul className="ml-6 list-disc space-y-3">
              {t.techList.map((tech) => (
                <li key={tech.name}>
                  <strong className="text-text-primary">{tech.name}</strong> — {tech.desc}
                </li>
              ))}
            </ul>
            <p className="mt-6 text-lg font-medium text-text-primary">{t.behindFooter}</p>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
