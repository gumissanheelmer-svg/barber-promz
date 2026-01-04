import { forwardRef } from 'react';
import { Scissors } from 'lucide-react';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
}

export const Logo = forwardRef<HTMLDivElement, LogoProps>(function Logo(
  { size = 'md', showText = true },
  ref
) {
  const sizeClasses = {
    sm: 'h-8 w-8',
    md: 'h-12 w-12',
    lg: 'h-20 w-20',
  };

  const textClasses = {
    sm: 'text-lg',
    md: 'text-2xl',
    lg: 'text-4xl',
  };

  return (
    <div ref={ref} className="flex items-center gap-3">
      <div className={`${sizeClasses[size]} relative flex items-center justify-center`}>
        <div className="absolute inset-0 bg-gradient-gold rounded-full opacity-20 blur-lg" />
        <div className="relative bg-gradient-gold rounded-full p-2 shadow-gold">
          <Scissors className={`${size === 'sm' ? 'h-4 w-4' : size === 'md' ? 'h-6 w-6' : 'h-10 w-10'} text-primary-foreground rotate-[-45deg]`} />
        </div>
      </div>
      {showText && (
        <div className="flex flex-col">
          <span className={`${textClasses[size]} font-display font-bold text-foreground`}>
            Barbearia
          </span>
          <span className="text-primary text-sm font-medium tracking-widest uppercase">
            Elite
          </span>
        </div>
      )}
    </div>
  );
});
