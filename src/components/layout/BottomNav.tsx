import React from 'react';
import { Home, Compass, PlusCircle, Bell, User } from 'lucide-react';

interface BottomNavProps {
  currentTab: 'home' | 'discover' | 'ask' | 'notifications' | 'profile';
  onTabChange: (tab: 'home' | 'discover' | 'ask' | 'notifications' | 'profile') => void;
  unreadNotificationsCount?: number;
}

export const BottomNav: React.FC<BottomNavProps> = ({
  currentTab,
  onTabChange,
  unreadNotificationsCount = 0,
}) => {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-md border-t border-zinc-200/80 dark:border-zinc-800 pb-[env(safe-area-inset-bottom,8px)] pt-1.5 transition-colors">
      <div className="max-w-md mx-auto grid grid-cols-5 items-center px-1">
        {/* 1. Home */}
        <button
          onClick={() => onTabChange('home')}
          className={`flex flex-col items-center justify-center py-1 transition-all ${
            currentTab === 'home'
              ? 'text-indigo-600 dark:text-indigo-400 font-semibold'
              : 'text-zinc-500 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200'
          }`}
        >
          <Home className="w-5 h-5 mb-0.5 stroke-[2]" />
          <span className="text-[11px] leading-tight">Home</span>
        </button>

        {/* 2. Discover */}
        <button
          onClick={() => onTabChange('discover')}
          className={`flex flex-col items-center justify-center py-1 transition-all ${
            currentTab === 'discover'
              ? 'text-indigo-600 dark:text-indigo-400 font-semibold'
              : 'text-zinc-500 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200'
          }`}
        >
          <Compass className="w-5 h-5 mb-0.5 stroke-[2]" />
          <span className="text-[11px] leading-tight">Discover</span>
        </button>

        {/* 3. Ask (Visually emphasized) */}
        <button
          onClick={() => onTabChange('ask')}
          className="flex flex-col items-center justify-center py-0.5 -mt-3.5 group focus:outline-none"
        >
          <div className="w-11 h-11 rounded-full bg-indigo-600 hover:bg-indigo-700 text-white flex items-center justify-center shadow-md shadow-indigo-600/30 group-active:scale-95 transition-all">
            <PlusCircle className="w-6 h-6 stroke-[2.2]" />
          </div>
          <span className="text-[11px] font-semibold text-zinc-700 dark:text-zinc-300 mt-0.5 leading-tight">
            Ask
          </span>
        </button>

        {/* 4. Notifications */}
        <button
          onClick={() => onTabChange('notifications')}
          className={`relative flex flex-col items-center justify-center py-1 transition-all ${
            currentTab === 'notifications'
              ? 'text-indigo-600 dark:text-indigo-400 font-semibold'
              : 'text-zinc-500 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200'
          }`}
        >
          <div className="relative">
            <Bell className="w-5 h-5 mb-0.5 stroke-[2]" />
            {unreadNotificationsCount > 0 && (
              <span className="absolute -top-1 -right-1.5 flex h-4 min-w-[16px] px-1 items-center justify-center rounded-full bg-rose-500 text-[9px] font-bold text-white shadow-xs">
                {unreadNotificationsCount > 9 ? '9+' : unreadNotificationsCount}
              </span>
            )}
          </div>
          <span className="text-[11px] leading-tight">Alerts</span>
        </button>

        {/* 5. Profile */}
        <button
          onClick={() => onTabChange('profile')}
          className={`flex flex-col items-center justify-center py-1 transition-all ${
            currentTab === 'profile'
              ? 'text-indigo-600 dark:text-indigo-400 font-semibold'
              : 'text-zinc-500 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200'
          }`}
        >
          <User className="w-5 h-5 mb-0.5 stroke-[2]" />
          <span className="text-[11px] leading-tight">Profile</span>
        </button>
      </div>
    </nav>
  );
};
