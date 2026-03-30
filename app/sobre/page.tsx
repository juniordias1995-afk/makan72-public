"use client";

import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Cpu, Network, Shield, Brain, Crown } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";
import { getAboutContent } from "@/lib/i18n";

export default function Sobre() {
  const { lang } = useLanguage();

  const t = getAboutContent(lang);

  return (
    <main className="min-h-screen">
      <Navbar />
      <div className="pt-32" />

      {/* Hero Section */}
      <section className="py-20">
        <div className="mx-auto max-w-4xl px-6">
          <div className="mb-8 inline-flex">
            <span className="flex items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-4 py-2 text-sm font-medium text-primary">
              <Crown className="h-4 w-4" />
              {t.badge}
            </span>
          </div>
          
          <h1 className="font-display text-4xl font-bold md:text-6xl">{t.title}</h1>
          
          <div className="mt-8 space-y-6 text-lg text-text-secondary">
            <p className="text-xl">{t.p1}</p>
            <p>{t.p2}</p>
            <p>{t.p3}</p>
          </div>
        </div>
      </section>

      {/* Architecture Diagram */}
      <section className="border-y border-border bg-bg-surface py-24">
        <div className="mx-auto max-w-6xl px-6">
          <div className="text-center">
            <h2 className="font-display text-3xl font-bold md:text-5xl">{t.architecture}</h2>
            <p className="mt-4 text-text-secondary">{t.architectureDesc}</p>
          </div>

          <div className="mt-16 flex flex-col items-center justify-center gap-6 md:flex-row md:gap-12">
            {t.nodes.map((node, index) => (
              <div key={node.label} className="flex items-center gap-6">
                <div className={`rounded-2xl border p-8 text-center shadow-card ${
                  index === 0 ? 'border-primary bg-primary/10' : 
                  index === 1 ? 'border-accent bg-accent/10' : 
                  'border-border bg-bg-main'
                }`}>
                  <p className="font-display text-2xl font-bold text-text-primary">
                    {node.label}
                    {node.sublabel && <span className="ml-2 text-primary">{node.sublabel}</span>}
                  </p>
                  <p className="mt-2 text-sm text-text-secondary">{node.action}</p>
                </div>
                
                {index < t.nodes.length - 1 && (
                  <div className="hidden h-1 w-12 bg-gradient-to-r from-primary to-accent md:block" />
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Benefits */}
      <section className="py-24">
        <div className="mx-auto max-w-6xl px-6">
          <h2 className="font-display text-3xl font-bold md:text-5xl text-center">{t.benefits}</h2>
          
          <div className="mt-16 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {t.benefitCards.map((item) => (
              <div key={item.title} className="group relative rounded-2xl border border-border bg-bg-surface p-8 shadow-soft transition-all duration-300 hover:shadow-card-hover hover:-translate-y-1">
                <h3 className="font-display text-xl font-bold text-text-primary">{item.title}</h3>
                <p className="mt-3 text-text-secondary">{item.desc}</p>
                <div className="absolute bottom-0 left-0 h-1 w-0 rounded-b-2xl bg-gradient-to-r from-primary to-accent transition-all duration-300 group-hover:w-full" />
              </div>
            ))}
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
