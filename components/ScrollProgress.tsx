"use client";

import { useState, useEffect } from "react";

interface ScrollProgressProps {
  color?: "primary" | "accent" | "gradient";
  height?: "sm" | "md" | "lg";
  showPercentage?: boolean;
}

export default function ScrollProgress({ 
  color = "gradient",
  height = "md",
  showPercentage = false
}: ScrollProgressProps) {
  const [scrollProgress, setScrollProgress] = useState(0);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      const totalHeight = document.documentElement.scrollHeight - window.innerHeight;
      const currentProgress = (window.scrollY / totalHeight) * 100;
      setScrollProgress(currentProgress);
      
      // Show progress bar only when scrolling down
      setIsVisible(window.scrollY > 100);
    };

    // Add scroll listener
    window.addEventListener("scroll", handleScroll);
    
    // Initial calculation
    handleScroll();

    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const heightClasses = {
    sm: "h-1",
    md: "h-2",
    lg: "h-3"
  };

  const colorClasses = {
    primary: "bg-primary",
    accent: "bg-accent",
    gradient: "bg-gradient-to-r from-primary via-accent to-primary"
  };

  if (!isVisible) return null;

  return (
    <div className="fixed top-0 left-0 right-0 z-50">
      {/* Background track */}
      <div className={`${heightClasses[height]} w-full bg-bg-surface/50 backdrop-blur-sm`}>
        {/* Progress bar */}
        <div 
          className={`${heightClasses[height]} ${colorClasses[color]} transition-all duration-300 ease-out`}
          style={{ width: `${scrollProgress}%` }}
        >
          {/* Glow effect */}
          <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-shimmer" />
        </div>
      </div>
      
      {/* Percentage indicator (optional) */}
      {showPercentage && (
        <div className="absolute right-4 top-2 flex items-center gap-2">
          <div className="rounded-full bg-bg-surface/80 backdrop-blur-sm px-3 py-1 text-xs font-medium text-text-primary border border-border/30">
            {Math.round(scrollProgress)}%
          </div>
          {/* Animated dot */}
          <div className="h-2 w-2 rounded-full bg-primary animate-ping" />
        </div>
      )}
    </div>
  );
}
