import React, { useState } from 'react';
import {
  X,
  Shield,
  Bell,
  Eye,
  Moon,
  Sun,
  FileText,
  Smartphone,
  LogOut,
  ChevronRight,
  AlertTriangle,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({ isOpen, onClose }) => {
  const {
    currentUser,
    signOut,
    isDarkMode,
    toggleDarkMode,
    isDeviceFrame,
    toggleDeviceFrame,
  } = useAuth();

  const [activeLegalModal, setActiveLegalModal] = useState<'tos' | 'privacy' | 'guidelines' | null>(
    null
  );

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-xs transition-opacity animate-in fade-in duration-200">
      <div className="relative w-full max-w-md max-h-[90vh] flex flex-col rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="px-5 py-3.5 border-b border-zinc-200/80 dark:border-zinc-800 flex items-center justify-between">
          <h2 className="text-sm font-bold text-zinc-900 dark:text-zinc-100">Settings</h2>
          <button
            onClick={onClose}
            className="p-1 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200 rounded-full"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Settings Body */}
        <div className="flex-1 overflow-y-auto p-4 space-y-5">
          {/* Appearance Section */}
          <div>
            <h3 className="text-[11px] uppercase font-semibold text-zinc-400 mb-2 px-1">
              Appearance &amp; Device
            </h3>
            <div className="rounded-2xl bg-zinc-50 dark:bg-zinc-800/60 border border-zinc-200/80 dark:border-zinc-700/60 divide-y divide-zinc-200/60 dark:divide-zinc-700/60">
              <div className="flex items-center justify-between p-3.5">
                <div className="flex items-center gap-2.5">
                  {isDarkMode ? (
                    <Sun className="w-4 h-4 text-amber-400" />
                  ) : (
                    <Moon className="w-4 h-4 text-zinc-600" />
                  )}
                  <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
                    Dark Theme
                  </span>
                </div>
                <button
                  onClick={toggleDarkMode}
                  className={`w-10 h-6 rounded-full p-0.5 transition-colors ${
                    isDarkMode ? 'bg-indigo-600' : 'bg-zinc-300'
                  }`}
                >
                  <div
                    className={`w-5 h-5 rounded-full bg-white transition-transform ${
                      isDarkMode ? 'translate-x-4' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              <div className="flex items-center justify-between p-3.5">
                <div className="flex items-center gap-2.5">
                  <Smartphone className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
                  <div className="flex flex-col">
                    <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
                      Mobile Device Frame
                    </span>
                    <span className="text-[10px] text-zinc-400">
                      Simulate native iPhone/Android bezel
                    </span>
                  </div>
                </div>
                <button
                  onClick={toggleDeviceFrame}
                  className={`w-10 h-6 rounded-full p-0.5 transition-colors ${
                    isDeviceFrame ? 'bg-indigo-600' : 'bg-zinc-300'
                  }`}
                >
                  <div
                    className={`w-5 h-5 rounded-full bg-white transition-transform ${
                      isDeviceFrame ? 'translate-x-4' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>

          {/* Privacy & Safety Section */}
          <div>
            <h3 className="text-[11px] uppercase font-semibold text-zinc-400 mb-2 px-1">
              Privacy &amp; Community
            </h3>
            <div className="rounded-2xl bg-zinc-50 dark:bg-zinc-800/60 border border-zinc-200/80 dark:border-zinc-700/60 divide-y divide-zinc-200/60 dark:divide-zinc-700/60">
              <div className="flex items-center justify-between p-3.5">
                <div className="flex items-center gap-2.5">
                  <Eye className="w-4 h-4 text-zinc-600 dark:text-zinc-300" />
                  <div className="flex flex-col">
                    <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
                      Anonymous Posting Enabled
                    </span>
                    <span className="text-[10px] text-zinc-400">
                      You can toggle per question and answer
                    </span>
                  </div>
                </div>
                <span className="text-xs font-semibold text-emerald-600 dark:text-emerald-400">
                  Active
                </span>
              </div>

              <div className="flex items-center justify-between p-3.5">
                <div className="flex items-center gap-2.5">
                  <Shield className="w-4 h-4 text-zinc-600 dark:text-zinc-300" />
                  <div className="flex flex-col">
                    <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
                      ABAC Security Enforcement
                    </span>
                    <span className="text-[10px] text-zinc-400">
                      Firestore Rules &amp; App Check validation
                    </span>
                  </div>
                </div>
                <span className="text-xs font-semibold text-indigo-600 dark:text-indigo-400">
                  Enforced
                </span>
              </div>
            </div>
          </div>

          {/* Legal & Safety Section */}
          <div>
            <h3 className="text-[11px] uppercase font-semibold text-zinc-400 mb-2 px-1">
              Legal &amp; Guidelines
            </h3>
            <div className="rounded-2xl bg-zinc-50 dark:bg-zinc-800/60 border border-zinc-200/80 dark:border-zinc-700/60 divide-y divide-zinc-200/60 dark:divide-zinc-700/60">
              <button
                onClick={() => setActiveLegalModal('guidelines')}
                className="w-full flex items-center justify-between p-3.5 text-left hover:bg-zinc-100 dark:hover:bg-zinc-750 transition-colors"
              >
                <div className="flex items-center gap-2.5">
                  <FileText className="w-4 h-4 text-zinc-500" />
                  <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
                    Community Guidelines
                  </span>
                </div>
                <ChevronRight className="w-4 h-4 text-zinc-400" />
              </button>

              <button
                onClick={() => setActiveLegalModal('tos')}
                className="w-full flex items-center justify-between p-3.5 text-left hover:bg-zinc-100 dark:hover:bg-zinc-750 transition-colors"
              >
                <div className="flex items-center gap-2.5">
                  <FileText className="w-4 h-4 text-zinc-500" />
                  <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
                    Terms of Service
                  </span>
                </div>
                <ChevronRight className="w-4 h-4 text-zinc-400" />
              </button>

              <button
                onClick={() => setActiveLegalModal('privacy')}
                className="w-full flex items-center justify-between p-3.5 text-left hover:bg-zinc-100 dark:hover:bg-zinc-750 transition-colors"
              >
                <div className="flex items-center gap-2.5">
                  <FileText className="w-4 h-4 text-zinc-500" />
                  <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
                    Privacy Policy
                  </span>
                </div>
                <ChevronRight className="w-4 h-4 text-zinc-400" />
              </button>
            </div>
          </div>

          {/* Account Actions */}
          {currentUser && (
            <div className="pt-2">
              <button
                onClick={() => {
                  signOut();
                  onClose();
                }}
                className="w-full flex items-center justify-center gap-2 p-3 rounded-2xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900/50 text-xs font-semibold hover:bg-rose-100 transition-all"
              >
                <LogOut className="w-4 h-4" />
                <span>Sign Out of OpenAsk</span>
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Legal Sub-Modal */}
      {activeLegalModal && (
        <div className="fixed inset-0 z-60 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs">
          <div className="relative w-full max-w-md max-h-[80vh] flex flex-col rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-5 shadow-2xl">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-zinc-900 dark:text-zinc-100">
                {activeLegalModal === 'tos' && 'Terms of Service'}
                {activeLegalModal === 'privacy' && 'Privacy Policy'}
                {activeLegalModal === 'guidelines' && 'Community Guidelines'}
              </h3>
              <button
                onClick={() => setActiveLegalModal(null)}
                className="p-1 text-zinc-400 hover:text-zinc-600 rounded-full"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto text-xs text-zinc-600 dark:text-zinc-400 space-y-2.5 leading-relaxed pr-1">
              {activeLegalModal === 'guidelines' && (
                <>
                  <p>
                    OpenAsk is dedicated to cultivating trustworthy, civil, and insightful discussions across 50 global topics.
                  </p>
                  <p className="font-semibold text-zinc-800 dark:text-zinc-200">1. Constructive Participation</p>
                  <p>Provide helpful, authentic answers. Be respectful of opposing perspectives and cultural diversity.</p>
                  <p className="font-semibold text-zinc-800 dark:text-zinc-200">2. Anonymous Integrity</p>
                  <p>Anonymous posting is protected to encourage candid questions. However, anonymous privileges must not be used to harass, defame, or bypass moderation rules.</p>
                  <p className="font-semibold text-zinc-800 dark:text-zinc-200">3. Zero Tolerance for Spam &amp; Abuse</p>
                  <p>Commercial link spam, automated bot activity, manipulation of votes, and harmful content result in swift account suspension.</p>
                </>
              )}
              {activeLegalModal === 'tos' && (
                <>
                  <p>Welcome to OpenAsk. By accessing our platform on mobile or web, you agree to these Terms of Service.</p>
                  <p className="font-semibold text-zinc-800 dark:text-zinc-200">Account Responsibility</p>
                  <p>You are responsible for maintaining the confidentiality of your authentication credentials and all activity under your profile.</p>
                  <p className="font-semibold text-zinc-800 dark:text-zinc-200">Content Ownership</p>
                  <p>You retain ownership of questions and answers you author. You grant OpenAsk a non-exclusive license to index, display, and distribute your contributions.</p>
                </>
              )}
              {activeLegalModal === 'privacy' && (
                <>
                  <p>OpenAsk values privacy by design. We strictly limit personal data collection to what is necessary to operate our global discussion network.</p>
                  <p className="font-semibold text-zinc-800 dark:text-zinc-200">Data Isolation</p>
                  <p>Your private email and internal credentials are never exposed publicly. When you post anonymously, your identity is masked from all public views.</p>
                </>
              )}
            </div>
            <button
              onClick={() => setActiveLegalModal(null)}
              className="mt-4 w-full py-2 rounded-xl bg-zinc-900 text-white dark:bg-white dark:text-zinc-900 text-xs font-semibold"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
