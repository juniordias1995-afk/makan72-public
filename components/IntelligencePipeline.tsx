"use client";

import { User, Cpu, Network, CheckCircle } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";

export default function IntelligencePipeline() {
  const { lang } = useLanguage();

  const content = {
    PT: {
      title: "O Pipeline de Inteligência",
      subtitle: "Você comanda. O Makan72 coordena. Os agentes executam.",
      nodes: [
        { icon: User, label: "Você", sublabel: "(CEO)", desc: "Define a missão", color: "primary" },
        { icon: Cpu, label: "Makan72", sublabel: "", desc: "Coordena e potencializa", color: "accent", isCentral: true },
        { icon: Network, label: "Agentes IA", sublabel: "", desc: "Claude · Gemini · Qwen · Goose", color: "primary" },
        { icon: CheckCircle, label: "Resultado", sublabel: "", desc: "Entregue com precisão", color: "accent" },
      ],
    },
    EN: {
      title: "The Intelligence Pipeline",
      subtitle: "You command. Makan72 coordinates. Agents execute.",
      nodes: [
        { icon: User, label: "You", sublabel: "(CEO)", desc: "Define the mission", color: "primary" },
        { icon: Cpu, label: "Makan72", sublabel: "", desc: "Coordinates & enhances", color: "accent", isCentral: true },
        { icon: Network, label: "AI Agents", sublabel: "", desc: "Claude · Gemini · Qwen · Goose", color: "primary" },
        { icon: CheckCircle, label: "Result", sublabel: "", desc: "Delivered with precision", color: "accent" },
      ],
    },
  };

  const data = content[lang];

  return (
    <section className="relative border-y border-border/30 bg-bg-surface/30 py-20 overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 grid-pattern opacity-[0.02]" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[300px] bg-gradient-to-r from-primary/5 via-accent/5 to-primary/5 rounded-full blur-3xl" />

      <div className="relative z-10 container-tight">
        {/* Header */}
        <div className="text-center mb-12">
          <h2 className="text-section text-text-primary">
            {data.title}
          </h2>
          <p className="mt-4 text-body-lg text-text-secondary max-w-xl mx-auto">
            {data.subtitle}
          </p>
        </div>

        {/* Pipeline - Desktop */}
        <div className="hidden md:block">
          <div className="relative">
            {/* Connection line */}
            <div className="absolute top-[50px] left-[12%] right-[12%] h-px">
              <div className="absolute inset-0 bg-gradient-to-r from-primary/30 via-accent/30 to-primary/30" />
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-primary/50 to-transparent animate-shimmer" />
            </div>

            {/* Nodes */}
            <div className="flex justify-between items-start">
              {data.nodes.map((node, index) => (
                <div key={node.label} className="flex flex-col items-center w-[180px]">
                  {/* Node */}
                  <div className={`relative group ${node.isCentral ? 'z-10' : ''}`}>
                    {/* Glow for central node */}
                    {node.isCentral && (
                      <div className="absolute inset-0 rounded-xl bg-accent/20 blur-xl animate-pulse-glow" />
                    )}
                    
                    {/* Node box */}
                    <div 
                      className={`relative flex h-[100px] w-[100px] items-center justify-center rounded-xl border-2 transition-all duration-500 ${
                        node.isCentral
                          ? 'border-accent bg-accent/10 shadow-elevated scale-110'
                          : 'border-border/50 bg-bg-surface glass hover:border-primary/30 hover:shadow-card'
                      }`}
                    >
                      <node.icon className={`h-8 w-8 transition-all duration-300 group-hover:scale-110 ${
                        node.isCentral ? 'text-accent' : 'text-text-secondary group-hover:text-primary'
                      }`} />
                      
                      {/* Pulse ring for central node */}
                      {node.isCentral && (
                        <div className="absolute inset-0 rounded-xl border-2 border-accent/30 animate-pulse-ring" />
                      )}
                    </div>

                    {/* Step number */}
                    <div className={`absolute -top-2 -right-2 flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold ${
                      node.isCentral
                        ? 'bg-accent text-white'
                        : 'bg-primary/10 text-primary'
                    }`}>
                      {index + 1}
                    </div>
                  </div>

                  {/* Label */}
                  <div className="mt-4 text-center">
                    <p className="text-lg font-display font-bold text-text-primary">
                      {node.label}
                      {node.sublabel && <span className="ml-1 text-primary text-sm">{node.sublabel}</span>}
                    </p>
                    <p className="mt-1 text-small text-text-secondary">{node.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Pipeline - Mobile */}
        <div className="flex flex-col items-center gap-6 md:hidden">
          {data.nodes.map((node, index) => (
            <div key={node.label} className="flex flex-col items-center w-full max-w-[260px]">
              {/* Node */}
              <div className={`relative flex h-16 w-16 items-center justify-center rounded-xl border-2 transition-all ${
                node.isCentral
                  ? 'border-accent bg-accent/10 shadow-card'
                  : 'border-border/50 bg-bg-surface'
              }`}>
                <node.icon className={`h-6 w-6 ${node.isCentral ? 'text-accent' : 'text-text-secondary'}`} />
              </div>

              {/* Label */}
              <div className="mt-3 text-center">
                <p className="font-display font-bold text-text-primary text-base">
                  {node.label}
                  {node.sublabel && <span className="ml-1 text-primary text-sm">{node.sublabel}</span>}
                </p>
                <p className="mt-1 text-small text-text-secondary">{node.desc}</p>
              </div>

              {/* Connector */}
              {index < data.nodes.length - 1 && (
                <div className="my-3 h-6 w-px bg-gradient-to-b from-primary/50 to-accent/50" />
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
