import React, { useEffect, useState } from 'react';
import { Wifi, Battery, Signal } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

interface MobileShellProps {
  children: React.ReactNode;
}

export const MobileShell: React.FC<MobileShellProps> = ({ children }) => {
  const { isDeviceFrame } = useAuth();
  const [time, setTime] = useState<string>('9:41');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTime(
        now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false })
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 30000);
    return () => clearInterval(interval);
  }, []);

  if (!isDeviceFrame) {
    // Standard full-width responsive mobile-first layout
    return (
      <div className="min-h-screen bg-zinc-50 dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 flex flex-col font-sans transition-colors">
        <div className="w-full max-w-md mx-auto flex-1 flex flex-col relative pb-20 shadow-xs bg-white dark:bg-zinc-900 min-h-screen border-x border-zinc-200/60 dark:border-zinc-800/60">
          {children}
        </div>
      </div>
    );
  }

  // Device Frame layout (for testing mobile experience on desktop)
  return (
    <div className="min-h-screen bg-zinc-200 dark:bg-zinc-950 flex items-center justify-center p-2 sm:p-6 transition-colors">
      <div className="relative w-full max-w-[430px] h-[890px] max-h-[96vh] rounded-[48px] bg-zinc-900 shadow-2xl ring-12 ring-zinc-800/80 dark:ring-zinc-800 flex flex-col overflow-hidden border-4 border-zinc-700/60">
        
        {/* Dynamic Island / Status Bar */}
        <div className="h-10 w-full bg-white dark:bg-zinc-900 text-zinc-900 dark:text-zinc-100 flex items-center justify-between px-7 shrink-0 z-50 select-none">
          <span className="text-xs font-semibold tracking-tight">{time}</span>
          
          {/* Dynamic Island Pill */}
          <div className="w-24 h-5 rounded-full bg-zinc-950 dark:bg-black mx-auto flex items-center justify-center gap-1.5 shadow-inner">
            <div className="w-2.5 h-2.5 rounded-full bg-zinc-900 dark:bg-zinc-950 border border-zinc-800" />
            <div className="w-2 h-2 rounded-full bg-indigo-500/20" />
          </div>

          <div className="flex items-center gap-1.5 text-zinc-700 dark:text-zinc-300">
            <Signal className="w-3.5 h-3.5" />
            <Wifi className="w-3.5 h-3.5" />
            <Battery className="w-4 h-4" />
          </div>
        </div>

        {/* Mobile Viewport Screen */}
        <div className="flex-1 w-full overflow-y-auto bg-zinc-50 dark:bg-zinc-900 text-zinc-900 dark:text-zinc-100 flex flex-col relative pb-16 custom-scrollbar">
          {children}
        </div>

        {/* iOS Home Indicator Bar */}
        <div className="absolute bottom-1 left-1/2 -translate-x-1/2 w-36 h-1 rounded-full bg-zinc-400/50 dark:bg-zinc-600/50 z-50 pointer-events-none" />
      </div>
    </div>
  );
};
