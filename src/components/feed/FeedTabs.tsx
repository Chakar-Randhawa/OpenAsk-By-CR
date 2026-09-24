import React, { useState, useEffect } from 'react';
import { Sparkles, TrendingUp, Clock, Users2, RefreshCw, HelpCircle } from 'lucide-react';
import { Question } from '../../types';
import { QuestionCard } from './QuestionCard';
import { EmptyState } from '../common/EmptyState';
import { fetchQuestions, getCategoryFollowedIds } from '../../services/firestoreService';
import { useAuth } from '../../context/AuthContext';

interface FeedTabsProps {
  onSelectQuestion: (questionId: string) => void;
  onSelectCategory: (categoryId: string) => void;
  onOpenReport: (targetType: 'question', targetId: string) => void;
  onOpenAsk: () => void;
}

export const FeedTabs: React.FC<FeedTabsProps> = ({
  onSelectQuestion,
  onSelectCategory,
  onOpenReport,
  onOpenAsk,
}) => {
  const { currentUser } = useAuth();
  const [activeTab, setActiveTab] = useState<'forYou' | 'trending' | 'new' | 'following'>('forYou');
  const [questions, setQuestions] = useState<Question[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadFeed = async (showLoadingSpinner = true) => {
    if (showLoadingSpinner) setLoading(true);
    try {
      let followedCats: string[] = [];
      if (currentUser) {
        const catSet = await getCategoryFollowedIds(currentUser.uid);
        followedCats = Array.from(catSet);
      }

      const items = await fetchQuestions({
        feedType: activeTab,
        followedCategories: followedCats,
      });
      setQuestions(items);
    } catch (err) {
      console.error('Failed to load feed:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadFeed(true);
  }, [activeTab, currentUser]);

  const handleRefresh = () => {
    setRefreshing(true);
    loadFeed(false);
  };

  const tabs = [
    { id: 'forYou', label: 'For You', icon: Sparkles },
    { id: 'trending', label: 'Trending', icon: TrendingUp },
    { id: 'new', label: 'New', icon: Clock },
    { id: 'following', label: 'Following', icon: Users2 },
  ] as const;

  return (
    <div className="flex flex-col flex-1">
      {/* Sticky Tab Header */}
      <div className="sticky top-[49px] z-20 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-md border-b border-zinc-200/80 dark:border-zinc-800 px-3 py-1 flex items-center justify-between">
        <div className="flex items-center gap-1 overflow-x-auto no-scrollbar py-0.5">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-all ${
                  isActive
                    ? 'bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 shadow-xs'
                    : 'text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        <button
          onClick={handleRefresh}
          disabled={refreshing}
          title="Refresh feed"
          aria-label="Refresh feed"
          className="p-1.5 rounded-full text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all shrink-0"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {/* Feed Content */}
      <div className="flex-1">
        {loading ? (
          <div className="p-4 space-y-4">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className="animate-pulse bg-white dark:bg-zinc-900 p-4 rounded-xl border border-zinc-200/60 dark:border-zinc-800/60 space-y-3"
              >
                <div className="h-4 bg-zinc-200 dark:bg-zinc-800 rounded w-1/4" />
                <div className="h-5 bg-zinc-200 dark:bg-zinc-800 rounded w-4/5" />
                <div className="h-3 bg-zinc-200 dark:bg-zinc-800 rounded w-full" />
                <div className="h-3 bg-zinc-200 dark:bg-zinc-800 rounded w-2/3" />
              </div>
            ))}
          </div>
        ) : questions.length === 0 ? (
          <EmptyState
            icon={HelpCircle}
            title={
              activeTab === 'following'
                ? 'No questions from followed sources'
                : 'No questions yet'
            }
            description={
              activeTab === 'following'
                ? 'Follow categories or active members to see tailored questions here.'
                : 'Be the first to spark a conversation. Ask anything publicly or anonymously.'
            }
            actionText="Ask a Question"
            onAction={onOpenAsk}
          />
        ) : (
          <div className="divide-y divide-zinc-150 dark:divide-zinc-800/80">
            {questions.map((question) => (
              <QuestionCard
                key={question.id}
                question={question}
                onSelect={onSelectQuestion}
                onSelectCategory={onSelectCategory}
                onOpenReport={onOpenReport}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
