import React from 'react';
import {
  Search,
  Moon,
  Sun,
  Smartphone,
  Maximize2,
  LogIn,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

interface NavbarProps {
  currentTab: string;
  onOpenSearch: () => void;
  onOpenAuth: () => void;
  onOpenProfile: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  currentTab,
  onOpenSearch,
  onOpenAuth,
  onOpenProfile,
}) => {
  const { currentUser, userProfile, isDarkMode, toggleDarkMode, isDeviceFrame, toggleDeviceFrame } =
    useAuth();

  return (
    <header className="sticky top-0 z-30 bg-white/90 dark:bg-zinc-900/90 backdrop-blur-md border-b border-zinc-200/80 dark:border-zinc-800 px-4 py-2.5 transition-colors">
      <div className="flex items-center justify-between">
        {/* Brand */}
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-indigo-600 via-indigo-700 to-violet-800 flex items-center justify-center text-white shadow-sm shadow-indigo-500/20">
            <span className="font-bold text-sm tracking-tight">O</span>
          </div>
          <div className="flex flex-col">
            <span className="text-base font-bold tracking-tight text-zinc-900 dark:text-white leading-tight">
              OpenAsk
            </span>
            <span className="text-[10px] uppercase font-semibold tracking-wider text-indigo-600 dark:text-indigo-400">
              Global Q&amp;A
            </span>
          </div>
        </div>

        {/* Action icons */}
        <div className="flex items-center gap-1">
          {/* Quick Search */}
          <button
            onClick={onOpenSearch}
            aria-label="Search OpenAsk"
            className="p-2 rounded-xl text-zinc-600 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 active:scale-95 transition-all"
          >
            <Search className="w-4 h-4" />
          </button>

          {/* Theme Toggle */}
          <button
            onClick={toggleDarkMode}
            aria-label="Toggle theme"
            className="p-2 rounded-xl text-zinc-600 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 active:scale-95 transition-all"
          >
            {isDarkMode ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4" />}
          </button>

          {/* Mobile Frame Toggle (visible on larger screens) */}
          <button
            onClick={toggleDeviceFrame}
            title={isDeviceFrame ? 'Switch to Full Width' : 'Switch to Mobile Frame'}
            aria-label="Toggle mobile device frame"
            className="hidden md:flex p-2 rounded-xl text-zinc-600 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 active:scale-95 transition-all"
          >
            {isDeviceFrame ? <Maximize2 className="w-4 h-4" /> : <Smartphone className="w-4 h-4" />}
          </button>

          {/* User Avatar or Sign In */}
          {currentUser ? (
            <button
              onClick={onOpenProfile}
              className="ml-1 flex items-center focus:outline-none"
            >
              {userProfile?.photoUrl ? (
                <img
                  src={userProfile.photoUrl}
                  alt={userProfile.displayName}
                  className="w-7 h-7 rounded-full object-cover ring-1 ring-zinc-300 dark:ring-zinc-700"
                />
              ) : (
                <div className="w-7 h-7 rounded-full bg-zinc-200 dark:bg-zinc-700 flex items-center justify-center text-xs font-semibold text-zinc-800 dark:text-zinc-200">
                  {userProfile?.displayName?.charAt(0).toUpperCase() || 'U'}
                </div>
              )}
            </button>
          ) : (
            <button
              onClick={onOpenAuth}
              className="ml-1 inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-indigo-600 hover:bg-indigo-700 active:scale-95 text-white transition-all shadow-xs"
            >
              <LogIn className="w-3.5 h-3.5" />
              <span>Sign In</span>
            </button>
          )}
        </div>
      </div>
    </header>
  );
};
