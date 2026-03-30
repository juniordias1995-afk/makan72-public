"use client";

import { LucideIcon } from "lucide-react";

interface FeatureCardProps {
  icon: LucideIcon;
  title: string;
  description: string;
  delay?: number;
}

export default function FeatureCard({
  icon: Icon,
  title,
  description,
  delay = 0,
}: FeatureCardProps) {
  return (
    <div
      className="group relative animate-fade-in-up"
      style={{ animationDelay: `${delay}ms` }}
    >
      {/* Glow effect */}
      <div className="absolute -inset-0.5 rounded-2xl bg-gradient-to-r from-primary to-accent opacity-0 blur transition duration-500 group-hover:opacity-30" />
      
      {/* Card */}
      <div className="relative h-full rounded-2xl border border-border/50 bg-bg-surface/80 p-6 glass card-3d">
        {/* Gradient overlay on hover */}
        <div className="absolute inset-0 rounded-2xl bg-gradient-to-br from-primary/5 via-transparent to-accent/5 opacity-0 transition-opacity duration-500 group-hover:opacity-100" />
        
        {/* Content */}
        <div className="relative z-10">
          {/* Icon */}
          <div className="mb-5">
            <div className="inline-flex h-12 w-12 items-center justify-center rounded-xl border border-primary/20 bg-primary/5 transition-all duration-500 group-hover:border-primary/40 group-hover:bg-primary/10 group-hover:scale-110 group-hover:rotate-3">
              <Icon className="h-6 w-6 text-primary transition-transform duration-500 group-hover:scale-125" />
            </div>
          </div>

          {/* Title - Using text-card-title (20-24px) */}
          <h3 className="text-card-title text-text-primary mb-3 font-semibold">
            {title}
          </h3>

          {/* Description - Using text-body (16px) */}
          <p className="text-body text-text-secondary">
            {description}
          </p>

          {/* Bottom accent line */}
          <div className="mt-5 h-0.5 w-10 rounded-full bg-gradient-to-r from-primary to-accent transition-all duration-500 group-hover:w-full" />
        </div>

        {/* Corner accents */}
        <div className="absolute top-0 right-0 h-12 w-12 overflow-hidden rounded-tr-2xl">
          <div className="absolute top-0 right-0 h-px w-6 bg-gradient-to-l from-primary/30 to-transparent transition-all duration-500 group-hover:w-12" />
          <div className="absolute top-0 right-0 h-6 w-px bg-gradient-to-b from-primary/30 to-transparent transition-all duration-500 group-hover:h-12" />
        </div>
      </div>
    </div>
  );
}
