"use client";

import { ReactNode, useState, useId } from "react";

interface TooltipProps {
  children: ReactNode;
  content: string;
  position?: "top" | "bottom" | "left" | "right";
  delay?: number;
  maxWidth?: string;
  className?: string;
}

export default function Tooltip({ 
  children, 
  content, 
  position = "top",
  delay = 300,
  maxWidth = "200px",
  className = ""
}: TooltipProps) {
  const [isVisible, setIsVisible] = useState(false);
  const [timeoutId, setTimeoutId] = useState<NodeJS.Timeout | null>(null);
  const id = useId();

  const showTooltip = () => {
    if (timeoutId) clearTimeout(timeoutId);
    const id = setTimeout(() => setIsVisible(true), delay);
    setTimeoutId(id);
  };

  const hideTooltip = () => {
    if (timeoutId) clearTimeout(timeoutId);
    setIsVisible(false);
  };

  const positionClasses = {
    top: "bottom-full mb-2 left-1/2 transform -translate-x-1/2",
    bottom: "top-full mt-2 left-1/2 transform -translate-x-1/2",
    left: "right-full mr-2 top-1/2 transform -translate-y-1/2",
    right: "left-full ml-2 top-1/2 transform -translate-y-1/2"
  };

  const arrowClasses = {
    top: "top-full left-1/2 transform -translate-x-1/2 border-4 border-transparent border-t-bg-surface/90",
    bottom: "bottom-full left-1/2 transform -translate-x-1/2 border-4 border-transparent border-b-bg-surface/90",
    left: "left-full top-1/2 transform -translate-y-1/2 border-4 border-transparent border-l-bg-surface/90",
    right: "right-full top-1/2 transform -translate-y-1/2 border-4 border-transparent border-r-bg-surface/90"
  };

  return (
    <div 
      className={`relative inline-block ${className}`}
      onMouseEnter={showTooltip}
      onMouseLeave={hideTooltip}
      onFocus={showTooltip}
      onBlur={hideTooltip}
      aria-describedby={`tooltip-${id}`}
    >
      {children}
      
      {isVisible && (
        <div 
          id={`tooltip-${id}`}
          role="tooltip"
          className={`absolute z-50 ${positionClasses[position]} pointer-events-none`}
          style={{ maxWidth }}
        >
          <div className="bg-bg-surface/90 backdrop-blur-sm text-text-primary text-sm px-3 py-2 rounded-lg border border-border shadow-lg animate-fade-in">
            {content}
            <div className={`absolute ${arrowClasses[position]}`} />
          </div>
        </div>
      )}
    </div>
  );
}
