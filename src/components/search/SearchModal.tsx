import React, { useState, useEffect } from 'react';
import { Search, X, MessageSquare, Compass, ArrowRight } from 'lucide-react';
import { Question, Category } from '../../types';
import { fetchQuestions, fetchCategories } from '../../services/firestoreService';

interface SearchModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectQuestion: (questionId: string) => void;
  onSelectCategory: (categoryId: string) => void;
}

export const SearchModal: React.FC<SearchModalProps> = ({
  isOpen,
  onClose,
  onSelectQuestion,
  onSelectCategory,
}) => {
  const [queryText, setQueryText] = useState('');
  const [allQuestions, setAllQuestions] = useState<Question[]>([]);
  const [allCategories, setAllCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setLoading(true);
      Promise.all([
        fetchQuestions({ feedType: 'new', maxLimit: 100 }),
        fetchCategories(),
      ])
        .then(([q, c]) => {
          setAllQuestions(q);
          setAllCategories(c);
        })
        .finally(() => setLoading(false));
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const normalized = queryText.toLowerCase().trim();

  const matchedQuestions = normalized
    ? allQuestions.filter(
        (q) =>
          q.title.toLowerCase().includes(normalized) ||
          q.body.toLowerCase().includes(normalized) ||
          q.tags?.some((t) => t.toLowerCase().includes(normalized))
      )
    : [];

  const matchedCategories = normalized
    ? allCategories.filter(
        (c) =>
          c.name.toLowerCase().includes(normalized) ||
          c.description.toLowerCase().includes(normalized)
      )
    : [];

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center p-3 pt-12 sm:pt-16 bg-black/60 backdrop-blur-xs transition-opacity animate-in fade-in duration-200">
      <div className="relative w-full max-w-md max-h-[85vh] flex flex-col rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xl overflow-hidden">
        {/* Search Input Bar */}
        <div className="p-3 border-b border-zinc-200/80 dark:border-zinc-800 flex items-center gap-2">
          <Search className="w-4 h-4 text-zinc-400 ml-1" />
          <input
            type="text"
            autoFocus
            value={queryText}
            onChange={(e) => setQueryText(e.target.value)}
            placeholder="Search questions, categories, tags..."
            className="flex-1 bg-transparent py-1.5 text-xs text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:outline-none"
          />
          {queryText && (
            <button
              onClick={() => setQueryText('')}
              className="p-1 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200 rounded-full"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          )}
          <button
            onClick={onClose}
            className="px-2.5 py-1 text-xs font-semibold text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200"
          >
            Cancel
          </button>
        </div>

        {/* Results List */}
        <div className="flex-1 overflow-y-auto p-3 space-y-4">
          {!queryText ? (
            <div className="py-12 text-center text-zinc-400">
              <Search className="w-8 h-8 mx-auto mb-2 opacity-30 stroke-[1.5]" />
              <p className="text-xs">Type a keyword to search OpenAsk discussions.</p>
            </div>
          ) : matchedQuestions.length === 0 && matchedCategories.length === 0 ? (
            <div className="py-12 text-center text-zinc-400">
              <p className="text-xs font-semibold text-zinc-600 dark:text-zinc-300">
                No results found
              </p>
              <p className="text-[11px] mt-1">
                Try searching for broader keywords or alternative terms.
              </p>
            </div>
          ) : (
            <>
              {/* Matched Categories */}
              {matchedCategories.length > 0 && (
                <div>
                  <h4 className="text-[11px] uppercase tracking-wider font-semibold text-zinc-400 mb-2 px-1">
                    Categories ({matchedCategories.length})
                  </h4>
                  <div className="space-y-1">
                    {matchedCategories.slice(0, 4).map((c) => (
                      <div
                        key={c.id}
                        onClick={() => {
                          onSelectCategory(c.id);
                          onClose();
                        }}
                        className="flex items-center justify-between p-2 rounded-xl hover:bg-zinc-100 dark:hover:bg-zinc-800 cursor-pointer transition-colors"
                      >
                        <div className="flex items-center gap-2">
                          <Compass className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
                          <span className="text-xs font-medium text-zinc-800 dark:text-zinc-200">
                            {c.name}
                          </span>
                        </div>
                        <ArrowRight className="w-3.5 h-3.5 text-zinc-400" />
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Matched Questions */}
              {matchedQuestions.length > 0 && (
                <div>
                  <h4 className="text-[11px] uppercase tracking-wider font-semibold text-zinc-400 mb-2 px-1">
                    Questions ({matchedQuestions.length})
                  </h4>
                  <div className="space-y-2">
                    {matchedQuestions.map((q) => (
                      <div
                        key={q.id}
                        onClick={() => {
                          onSelectQuestion(q.id);
                          onClose();
                        }}
                        className="p-2.5 rounded-xl border border-zinc-200/80 dark:border-zinc-800 hover:border-indigo-500/40 hover:bg-zinc-50 dark:hover:bg-zinc-850 cursor-pointer transition-all"
                      >
                        <span className="inline-block px-1.5 py-0.5 rounded text-[10px] font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 mb-1">
                          {q.categoryName}
                        </span>
                        <h5 className="text-xs font-semibold text-zinc-900 dark:text-zinc-100 line-clamp-2">
                          {q.title}
                        </h5>
                        <p className="text-[11px] text-zinc-500 dark:text-zinc-400 line-clamp-1 mt-0.5">
                          {q.body}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};
