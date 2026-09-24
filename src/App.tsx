import React, { useState, useEffect } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { MobileShell } from './components/layout/MobileShell';
import { Navbar } from './components/layout/Navbar';
import { BottomNav } from './components/layout/BottomNav';
import { FeedTabs } from './components/feed/FeedTabs';
import { DiscoverView } from './components/discover/DiscoverView';
import { NotificationsView } from './components/notifications/NotificationsView';
import { ProfileView } from './components/profile/ProfileView';
import { QuestionDetailView } from './components/questions/QuestionDetailView';
import { AskQuestionModal } from './components/questions/AskQuestionModal';
import { AuthModal } from './components/auth/AuthModal';
import { SearchModal } from './components/search/SearchModal';
import { SettingsModal } from './components/settings/SettingsModal';
import { ReportModal } from './components/moderation/ReportModal';
import { fetchUserNotifications } from './services/firestoreService';

type Tab = 'home' | 'discover' | 'ask' | 'notifications' | 'profile';

function MainApp() {
  const { currentUser } = useAuth();

  // Navigation state
  const [currentTab, setCurrentTab] = useState<Tab>('home');
  const [activeQuestionId, setActiveQuestionId] = useState<string | null>(null);
  const [drilldownCategoryId, setDrilldownCategoryId] = useState<string | undefined>(undefined);

  // Modals state
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const [authInitialMode, setAuthInitialMode] = useState<'signin' | 'signup'>('signin');
  const [isAskOpen, setIsAskOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  // Report modal state
  const [reportState, setReportState] = useState<{
    isOpen: boolean;
    targetType: 'question' | 'answer' | 'user';
    targetId: string;
  }>({
    isOpen: false,
    targetType: 'question',
    targetId: '',
  });

  // Unread notifications badge
  const [unreadCount, setUnreadCount] = useState<number>(0);

  const refreshUnreadCount = async () => {
    if (currentUser) {
      try {
        const notifs = await fetchUserNotifications(currentUser.uid);
        const unread = notifs.filter((n) => !n.isRead).length;
        setUnreadCount(unread);
      } catch (err) {
        console.error(err);
      }
    } else {
      setUnreadCount(0);
    }
  };

  useEffect(() => {
    refreshUnreadCount();
    const interval = setInterval(refreshUnreadCount, 45000);
    return () => clearInterval(interval);
  }, [currentUser]);

  // Tab change handler
  const handleTabChange = (tab: Tab) => {
    if (tab === 'ask') {
      if (!currentUser) {
        setAuthInitialMode('signin');
        setIsAuthOpen(true);
      } else {
        setIsAskOpen(true);
      }
      return;
    }

    // Reset drilldown view when moving between tabs
    setActiveQuestionId(null);
    setCurrentTab(tab);
  };

  const handleOpenReport = (targetType: 'question' | 'answer' | 'user', targetId: string) => {
    if (!currentUser) {
      setAuthInitialMode('signin');
      setIsAuthOpen(true);
      return;
    }
    setReportState({
      isOpen: true,
      targetType,
      targetId,
    });
  };

  const handleSelectQuestion = (qId: string) => {
    setActiveQuestionId(qId);
  };

  const handleSelectCategory = (catId: string) => {
    setActiveQuestionId(null);
    setDrilldownCategoryId(catId);
    setCurrentTab('discover');
  };

  const handleQuestionCreated = (newQId: string) => {
    setActiveQuestionId(newQId);
    setCurrentTab('home');
  };

  return (
    <MobileShell>
      {/* Top Navbar */}
      <Navbar
        currentTab={currentTab}
        onOpenSearch={() => setIsSearchOpen(true)}
        onOpenAuth={() => {
          setAuthInitialMode('signin');
          setIsAuthOpen(true);
        }}
        onOpenProfile={() => {
          if (currentUser) {
            setActiveQuestionId(null);
            setCurrentTab('profile');
          } else {
            setAuthInitialMode('signin');
            setIsAuthOpen(true);
          }
        }}
      />

      {/* Main Viewport Router */}
      <main className="flex-1 flex flex-col">
        {activeQuestionId ? (
          <QuestionDetailView
            questionId={activeQuestionId}
            onBack={() => setActiveQuestionId(null)}
            onSelectCategory={handleSelectCategory}
            onOpenReport={handleOpenReport}
            onOpenAuth={() => {
              setAuthInitialMode('signin');
              setIsAuthOpen(true);
            }}
          />
        ) : (
          <>
            {currentTab === 'home' && (
              <FeedTabs
                onSelectQuestion={handleSelectQuestion}
                onSelectCategory={handleSelectCategory}
                onOpenReport={handleOpenReport}
                onOpenAsk={() => {
                  if (!currentUser) {
                    setAuthInitialMode('signin');
                    setIsAuthOpen(true);
                  } else {
                    setIsAskOpen(true);
                  }
                }}
              />
            )}

            {currentTab === 'discover' && (
              <DiscoverView
                onSelectQuestion={handleSelectQuestion}
                onOpenReport={handleOpenReport}
                onOpenAuth={() => {
                  setAuthInitialMode('signin');
                  setIsAuthOpen(true);
                }}
                initialCategoryId={drilldownCategoryId}
                onClearCategorySelection={() => setDrilldownCategoryId(undefined)}
              />
            )}

            {currentTab === 'notifications' && (
              <NotificationsView
                onSelectQuestion={handleSelectQuestion}
                onOpenAuth={() => {
                  setAuthInitialMode('signin');
                  setIsAuthOpen(true);
                }}
                onRefreshBadge={refreshUnreadCount}
              />
            )}

            {currentTab === 'profile' && (
              <ProfileView
                onSelectQuestion={handleSelectQuestion}
                onOpenSettings={() => setIsSettingsOpen(true)}
                onOpenAuth={() => {
                  setAuthInitialMode('signin');
                  setIsAuthOpen(true);
                }}
              />
            )}
          </>
        )}
      </main>

      {/* Persistent Bottom Navigation */}
      <BottomNav
        currentTab={currentTab}
        onTabChange={handleTabChange}
        unreadNotificationsCount={unreadCount}
      />

      {/* Global Modals */}
      <AuthModal
        isOpen={isAuthOpen}
        onClose={() => setIsAuthOpen(false)}
        initialMode={authInitialMode}
      />

      <AskQuestionModal
        isOpen={isAskOpen}
        onClose={() => setIsAskOpen(false)}
        onQuestionCreated={handleQuestionCreated}
        defaultCategoryId={drilldownCategoryId}
      />

      <SearchModal
        isOpen={isSearchOpen}
        onClose={() => setIsSearchOpen(false)}
        onSelectQuestion={(qId) => {
          setIsSearchOpen(false);
          setActiveQuestionId(qId);
        }}
        onSelectCategory={(catId) => {
          setIsSearchOpen(false);
          handleSelectCategory(catId);
        }}
      />

      <SettingsModal
        isOpen={isSettingsOpen}
        onClose={() => setIsSettingsOpen(false)}
      />

      <ReportModal
        isOpen={reportState.isOpen}
        onClose={() => setReportState((prev) => ({ ...prev, isOpen: false }))}
        targetType={reportState.targetType}
        targetId={reportState.targetId}
      />
    </MobileShell>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <MainApp />
    </AuthProvider>
  );
}
