import React, { useState, useEffect } from 'react';
import { Search, Compass, Check, Plus, ArrowLeft } from 'lucide-react';
import { Category, Question } from '../../types';
import { getCategoryIcon } from '../../utils/categoryIcons';
import {
  fetchCategories,
  followCategory,
  getCategoryFollowedIds,
  fetchQuestions,
} from '../../services/firestoreService';
import { useAuth } from '../../context/AuthContext';
import { QuestionCard } from '../feed/QuestionCard';
import { EmptyState } from '../common/EmptyState';

interface DiscoverViewProps {
  onSelectQuestion: (questionId: string) => void;
  onOpenReport: (targetType: 'question', targetId: string) => void;
  onOpenAuth: () => void;
  initialCategoryId?: string;
  onClearCategorySelection?: () => void;
}

export const DiscoverView: React.FC<DiscoverViewProps> = ({
  onSelectQuestion,
  onOpenReport,
  onOpenAuth,
  initialCategoryId,
  onClearCategorySelection,
}) => {
  const { currentUser } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);
  const [followedCategoryIds, setFollowedCategoryIds] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);

  // Drilldown category state
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [categoryQuestions, setCategoryQuestions] = useState<Question[]>([]);
  const [loadingCategoryQuestions, setLoadingCategoryQuestions] = useState(false);

  useEffect(() => {
    loadCategories();
  }, [currentUser]);

  const loadCategories = async () => {
    try {
      const cats = await fetchCategories();
      setCategories(cats);

      if (currentUser) {
        const followed = await getCategoryFollowedIds(currentUser.uid);
        setFollowedCategoryIds(followed);
      }

      if (initialCategoryId) {
        const found = cats.find((c) => c.id === initialCategoryId);
        if (found) {
          handleSelectCategory(found);
        }
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleSelectCategory = async (cat: Category) => {
    setSelectedCategory(cat);
    setLoadingCategoryQuestions(true);
    try {
      const questions = await fetchQuestions({
        feedType: 'forYou',
        categoryId: cat.id,
      });
      setCategoryQuestions(questions);
    } catch (err) {
      console.error(err);
    } finally {
      setLoadingCategoryQuestions(false);
    }
  };

  const handleToggleFollow = async (e: React.MouseEvent, categoryId: string) => {
    e.stopPropagation();
    if (!currentUser) {
      onOpenAuth();
      return;
    }
    try {
      const isNowFollowed = await followCategory(categoryId, currentUser.uid);
      setFollowedCategoryIds((prev) => {
        const next = new Set(prev);
        if (isNowFollowed) {
          next.add(categoryId);
        } else {
          next.delete(categoryId);
        }
        return next;
      });

      // Update count locally
      setCategories((prev) =>
        prev.map((c) =>
          c.id === categoryId
            ? { ...c, followerCount: (c.followerCount || 0) + (isNowFollowed ? 1 : -1) }
            : c
        )
      );

      if (selectedCategory && selectedCategory.id === categoryId) {
        setSelectedCategory((prev) =>
          prev
            ? {
                ...prev,
                followerCount: (prev.followerCount || 0) + (isNowFollowed ? 1 : -1),
              }
            : null
        );
      }
    } catch (err) {
      console.error(err);
    }
  };

  // Filter categories by search
  const filteredCategories = categories.filter((c) => {
    const q = searchQuery.toLowerCase().trim();
    if (!q) return true;
    return c.name.toLowerCase().includes(q) || c.description.toLowerCase().includes(q);
  });

  return (
    <div className="flex flex-col flex-1 pb-16">
      {/* Category Drilldown View */}
      {selectedCategory ? (
        <div className="flex flex-col">
          {/* Header */}
          <div className="sticky top-[49px] z-20 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-md border-b border-zinc-200/80 dark:border-zinc-800 px-3 py-2 flex items-center justify-between">
            <button
              onClick={() => {
                setSelectedCategory(null);
                onClearCategorySelection?.();
              }}
              className="flex items-center gap-1.5 text-xs font-semibold text-zinc-700 dark:text-zinc-300 hover:text-indigo-600 transition-colors p-1"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>All Topics</span>
            </button>

            <button
              onClick={(e) => handleToggleFollow(e, selectedCategory.id)}
              className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold transition-all ${
                followedCategoryIds.has(selectedCategory.id)
                  ? 'bg-zinc-200 dark:bg-zinc-800 text-zinc-800 dark:text-zinc-200'
                  : 'bg-indigo-600 hover:bg-indigo-700 text-white'
              }`}
            >
              {followedCategoryIds.has(selectedCategory.id) ? (
                <>
                  <Check className="w-3.5 h-3.5" />
                  <span>Following</span>
                </>
              ) : (
                <>
                  <Plus className="w-3.5 h-3.5" />
                  <span>Follow</span>
                </>
              )}
            </button>
          </div>

          {/* Category Banner Details */}
          <div className="p-4 bg-white dark:bg-zinc-900 border-b border-zinc-200/80 dark:border-zinc-800">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 rounded-2xl bg-indigo-50 dark:bg-indigo-950/50 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
                {React.createElement(getCategoryIcon(selectedCategory.icon), {
                  className: 'w-5 h-5',
                })}
              </div>
              <div>
                <h1 className="text-base font-bold text-zinc-900 dark:text-zinc-100">
                  {selectedCategory.name}
                </h1>
                <p className="text-xs text-zinc-500">
                  {selectedCategory.followerCount || 0} followers •{' '}
                  {categoryQuestions.length} questions
                </p>
              </div>
            </div>
            <p className="text-xs text-zinc-600 dark:text-zinc-400 leading-relaxed">
              {selectedCategory.description}
            </p>
          </div>

          {/* Category Questions List */}
          <div>
            {loadingCategoryQuestions ? (
              <div className="p-4 space-y-3">
                {[1, 2, 3].map((i) => (
                  <div
                    key={i}
                    className="h-24 bg-white dark:bg-zinc-900 rounded-xl animate-pulse p-4 border border-zinc-200/60 dark:border-zinc-800/60"
                  />
                ))}
              </div>
            ) : categoryQuestions.length === 0 ? (
              <EmptyState
                icon={Compass}
                title="No questions in this category yet"
                description={`Be the first to post a question under ${selectedCategory.name}.`}
              />
            ) : (
              <div className="divide-y divide-zinc-150 dark:divide-zinc-800/80">
                {categoryQuestions.map((q) => (
                  <QuestionCard
                    key={q.id}
                    question={q}
                    onSelect={onSelectQuestion}
                    onOpenReport={onOpenReport}
                  />
                ))}
              </div>
            )}
          </div>
        </div>
      ) : (
        /* Main Categories Browser */
        <div className="flex flex-col">
          {/* Search Header */}
          <div className="p-3 bg-white dark:bg-zinc-900 border-b border-zinc-200/80 dark:border-zinc-800 sticky top-[49px] z-20">
            <div className="relative">
              <Search className="absolute left-3 top-2.5 w-4 h-4 text-zinc-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search across 50 topics & discussions..."
                className="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-zinc-100 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
              />
            </div>
          </div>

          {/* Topics Subheading */}
          <div className="px-4 py-2.5 bg-zinc-50 dark:bg-zinc-950/40 border-b border-zinc-200/60 dark:border-zinc-800/60 flex items-center justify-between text-xs font-semibold text-zinc-700 dark:text-zinc-300">
            <span>Official Categories ({filteredCategories.length})</span>
            <span className="text-[11px] font-normal text-zinc-400">Tap to explore</span>
          </div>

          {/* 50 Categories Grid */}
          <div className="p-3 grid grid-cols-1 sm:grid-cols-2 gap-2">
            {filteredCategories.map((cat) => {
              const Icon = getCategoryIcon(cat.icon);
              const isFollowed = followedCategoryIds.has(cat.id);

              return (
                <div
                  key={cat.id}
                  onClick={() => handleSelectCategory(cat)}
                  className="flex items-center justify-between p-3 rounded-2xl bg-white dark:bg-zinc-850/80 border border-zinc-200/80 dark:border-zinc-800 hover:border-indigo-500/40 active:scale-98 transition-all cursor-pointer shadow-xs"
                >
                  <div className="flex items-center gap-3 min-w-0 pr-2">
                    <div className="w-9 h-9 rounded-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center text-indigo-600 dark:text-indigo-400 shrink-0">
                      <Icon className="w-4 h-4" />
                    </div>
                    <div className="min-w-0">
                      <h3 className="text-xs font-semibold text-zinc-900 dark:text-zinc-100 truncate">
                        {cat.name}
                      </h3>
                      <p className="text-[11px] text-zinc-500 dark:text-zinc-400 line-clamp-1">
                        {cat.description}
                      </p>
                    </div>
                  </div>

                  {/* Follow Button */}
                  <button
                    onClick={(e) => handleToggleFollow(e, cat.id)}
                    className={`p-1.5 rounded-lg shrink-0 transition-colors ${
                      isFollowed
                        ? 'bg-zinc-100 dark:bg-zinc-700 text-indigo-600 dark:text-indigo-400'
                        : 'text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200'
                    }`}
                  >
                    {isFollowed ? (
                      <Check className="w-4 h-4" />
                    ) : (
                      <Plus className="w-4 h-4" />
                    )}
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};
