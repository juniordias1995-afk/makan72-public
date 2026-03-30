"use client";

interface SkeletonLoaderProps {
  type?: "card" | "text" | "list" | "grid";
  count?: number;
  className?: string;
}

export default function SkeletonLoader({ 
  type = "card", 
  count = 1,
  className = ""
}: SkeletonLoaderProps) {
  const renderCardSkeleton = () => (
    <div className="group relative overflow-hidden rounded-3xl border border-border/30 bg-bg-surface/50 p-8">
      {/* Animated gradient background */}
      <div className="absolute inset-0 bg-gradient-to-r from-transparent via-border/10 to-transparent animate-shimmer" />
      
      {/* Content skeleton */}
      <div className="relative z-10">
        {/* Icon skeleton */}
        <div className="mb-8">
          <div className="h-16 w-16 rounded-2xl bg-border/30 animate-pulse" />
        </div>
        
        {/* Title skeleton */}
        <div className="mb-4">
          <div className="h-8 w-3/4 rounded-lg bg-border/40 animate-pulse" />
        </div>
        
        {/* Description skeleton */}
        <div className="space-y-3">
          <div className="h-4 w-full rounded bg-border/30 animate-pulse" />
          <div className="h-4 w-5/6 rounded bg-border/30 animate-pulse" />
          <div className="h-4 w-4/5 rounded bg-border/30 animate-pulse" />
        </div>
        
        {/* Bottom line skeleton */}
        <div className="mt-8">
          <div className="h-2 w-1/3 rounded-full bg-border/30 animate-pulse" />
        </div>
      </div>
    </div>
  );

  const renderTextSkeleton = () => (
    <div className="space-y-4">
      <div className="h-8 w-3/4 rounded-lg bg-border/30 animate-pulse" />
      <div className="space-y-3">
        <div className="h-4 w-full rounded bg-border/20 animate-pulse" />
        <div className="h-4 w-5/6 rounded bg-border/20 animate-pulse" />
        <div className="h-4 w-4/5 rounded bg-border/20 animate-pulse" />
        <div className="h-4 w-full rounded bg-border/20 animate-pulse" />
        <div className="h-4 w-3/4 rounded bg-border/20 animate-pulse" />
      </div>
    </div>
  );

  const renderListSkeleton = () => (
    <div className="space-y-6">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="flex items-center gap-4">
          <div className="h-12 w-12 rounded-xl bg-border/30 animate-pulse" />
          <div className="flex-1 space-y-2">
            <div className="h-5 w-1/3 rounded bg-border/40 animate-pulse" />
            <div className="h-4 w-2/3 rounded bg-border/30 animate-pulse" />
          </div>
        </div>
      ))}
    </div>
  );

  const renderGridSkeleton = () => (
    <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="group relative overflow-hidden rounded-2xl border border-border/30 bg-bg-surface/30 p-6">
          <div className="absolute inset-0 bg-gradient-to-r from-transparent via-border/5 to-transparent animate-shimmer" />
          <div className="relative z-10 space-y-4">
            <div className="h-12 w-12 rounded-xl bg-border/30 animate-pulse" />
            <div className="h-6 w-2/3 rounded bg-border/40 animate-pulse" />
            <div className="space-y-2">
              <div className="h-4 w-full rounded bg-border/30 animate-pulse" />
              <div className="h-4 w-5/6 rounded bg-border/30 animate-pulse" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );

  const renderContent = () => {
    switch (type) {
      case "card":
        return count === 1 ? renderCardSkeleton() : (
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: count }).map((_, i) => (
              <div key={i} className="animate-fade-in" style={{ animationDelay: `${i * 100}ms` }}>
                {renderCardSkeleton()}
              </div>
            ))}
          </div>
        );
      case "text":
        return renderTextSkeleton();
      case "list":
        return renderListSkeleton();
      case "grid":
        return renderGridSkeleton();
      default:
        return renderCardSkeleton();
    }
  };

  return (
    <div className={`${className}`}>
      {renderContent()}
    </div>
  );
}
