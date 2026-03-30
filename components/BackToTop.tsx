"use client";

import { useState, useEffect } from "react";
import { ArrowUp } from "lucide-react";

interface BackToTopProps {
  threshold?: number;
  position?: "bottom-right" | "bottom-left" | "bottom-center";
  showScrollPercentage?: boolean;
}

export default function BackToTop({ 
  threshold = 300,
  position = "bottom-right",
  showScrollPercentage = false
}: BackToTopProps) {
  const [isVisible, setIsVisible] = useState(false);
  const [scrollPercentage, setScrollPercentage] = useState(0);

  useEffect(() => {
    const handleScroll = () => {
      const scrolled = window.scrollY;
      setIsVisible(scrolled > threshold);
      
      // Calculate scroll percentage
      const totalHeight = document.documentElement.scrollHeight - window.innerHeight;
      const currentPercentage = (scrolled / totalHeight) * 100;
      setScrollPercentage(currentPercentage);
    };

    window.addEventListener("scroll", handleScroll);
    handleScroll(); // Initial check

    return () => window.removeEventListener("scroll", handleScroll);
  }, [threshold]);

  const scrollToTop = () => {
    window.scrollTo({
      top: 0,
      behavior: "smooth"
    });
  };

  const positionClasses = {
    "bottom-right": "bottom-6 right-6",
    "bottom-left": "bottom-6 left-6",
    "bottom-center": "bottom-6 left-1/2 transform -translate-x-1/2"
  };

  if (!isVisible) return null;

  return (
    <div className={`fixed z-40 ${positionClasses[position]}`}>
      <div className="group relative">
        {/* Background glow */}
        <div className="absolute -inset-4 rounded-full bg-gradient-to-r from-primary/20 via-accent/20 to-primary/20 opacity-0 group-hover:opacity-100 blur-xl transition-opacity duration-500" />
        
        {/* Main button */}
        <button
          onClick={scrollToTop}
          className="relative flex items-center justify-center rounded-full bg-bg-surface/80 backdrop-blur-lg border border-border/50 shadow-lg hover:shadow-xl transition-all duration-300 group-hover:scale-105 group-hover:border-primary/50"
          aria-label="Voltar ao topo"
        >
          {/* Progress ring (optional) */}
          {showScrollPercentage && (
            <div className="absolute inset-0">
              <svg className="w-14 h-14 transform -rotate-90" viewBox="0 0 50 50">
                <circle
                  cx="25"
                  cy="25"
                  r="20"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  className="text-border/30"
                />
                <circle
                  cx="25"
                  cy="25"
                  r="20"
                  fill="none"
                  stroke="url(#gradient)"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeDasharray="125.6"
                  strokeDashoffset={125.6 - (125.6 * scrollPercentage) / 100}
                  className="transition-all duration-300"
                />
                <defs>
                  <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" style={{ stopColor: 'var(--primary)' }} />
                    <stop offset="100%" style={{ stopColor: 'var(--accent)' }} />
                  </linearGradient>
                </defs>
              </svg>
            </div>
          )}
          
          {/* Arrow icon */}
          <div className={`p-3 ${showScrollPercentage ? 'p-4' : 'p-3'}`}>
            <ArrowUp className={`${showScrollPercentage ? 'h-5 w-5' : 'h-6 w-6'} text-text-secondary group-hover:text-primary transition-all duration-300 group-hover:-translate-y-1`} />
          </div>
          
          {/* Percentage text (optional) */}
          {showScrollPercentage && (
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="text-xs font-bold text-text-primary">
                {Math.round(scrollPercentage)}%
              </span>
            </div>
          )}
        </button>
        
        {/* Tooltip */}
        <div className="absolute bottom-full mb-2 left-1/2 transform -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none">
          <div className="bg-bg-surface/90 backdrop-blur-sm text-xs text-text-primary px-3 py-1.5 rounded-lg border border-border whitespace-nowrap">
            Voltar ao topo
            <div className="absolute top-full left-1/2 transform -translate-x-1/2 border-4 border-transparent border-t-bg-surface/90" />
          </div>
        </div>
      </div>
    </div>
  );
}
