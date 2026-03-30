"use client";

import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Footer from "@/components/Footer";
import FeatureCard from "@/components/FeatureCard";
import IntelligencePipeline from "@/components/IntelligencePipeline";
import HowItWorks from "@/components/HowItWorks";
import { useLanguage } from "@/context/LanguageContext";
import { getHomeContent } from "@/lib/i18n";

export default function Home() {
  const { lang } = useLanguage();

  const t = getHomeContent(lang);

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
