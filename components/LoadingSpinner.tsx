"use client";

interface LoadingSpinnerProps {
  size?: "sm" | "md" | "lg" | "xl";
  variant?: "primary" | "accent" | "white";
  label?: string;
  fullScreen?: boolean;
}

export default function LoadingSpinner({ 
  size = "md", 
  variant = "primary",
  label,
  fullScreen = false
}: LoadingSpinnerProps) {
  const sizeClasses = {
    sm: "h-8 w-8",
    md: "h-12 w-12",
    lg: "h-16 w-16",
    xl: "h-24 w-24"
  };

  const variantClasses = {
    primary: "text-primary",
    accent: "text-accent",
    white: "text-white"
  };

  const spinner = (
    <div className="relative">
      {/* Outer ring */}
      <div className={`${sizeClasses[size]} ${variantClasses[variant]} animate-spin rounded-full border-4 border-current border-t-transparent`} />
      
      {/* Inner ring */}
      <div className={`absolute inset-0 ${sizeClasses[size]} animate-spin rounded-full border-4 border-current border-t-transparent opacity-30`} style={{ animationDirection: 'reverse', animationDuration: '1.5s' }} />
      
      {/* Pulsing dot */}
      <div className="absolute inset-0 flex items-center justify-center">
        <div className={`h-1/4 w-1/4 rounded-full bg-current animate-ping opacity-75`} style={{ animationDuration: '2s' }} />
      </div>
    </div>
  );

  if (fullScreen) {
    return (
      <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-bg-primary/80 backdrop-blur-sm">
        <div className="relative">
          {spinner}
          {/* Glow effect */}
          <div className="absolute -inset-8 rounded-full bg-gradient-to-r from-primary/20 to-accent/20 blur-xl animate-pulse" />
        </div>
        {label && (
          <p className="mt-8 font-display text-xl font-medium text-text-primary animate-fade-in">
            {label}
          </p>
        )}
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center p-8">
      <div className="relative">
        {spinner}
        {/* Subtle glow */}
        <div className="absolute -inset-4 rounded-full bg-gradient-to-r from-primary/10 to-accent/10 blur-lg opacity-0 animate-pulse" style={{ animationDuration: '3s' }} />
      </div>
      {label && (
        <p className="mt-6 font-medium text-text-secondary animate-fade-in-up" style={{ animationDelay: '300ms' }}>
          {label}
        </p>
      )}
    </div>
  );
}
