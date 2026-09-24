import React, { useState } from 'react';
import {
  MessageSquare,
  Eye,
  Bookmark,
  Share2,
  CheckCircle,
  MoreVertical,
  Flag,
  UserCheck,
} from 'lucide-react';
import { Question } from '../../types';
import { formatRelativeTime, formatCompactNumber } from '../../utils/formatters';
import { useAuth } from '../../context/AuthContext';
import { toggleSaveQuestion } from '../../services/firestoreService';

interface QuestionCardProps {
  question: Question;
  onSelect: (questionId: string) => void;
  onSelectCategory?: (categoryId: string) => void;
  onOpenReport?: (targetType: 'question', targetId: string) => void;
  initialSaved?: boolean;
}

export const QuestionCard: React.FC<QuestionCardProps> = ({
  question,
  onSelect,
  onSelectCategory,
  onOpenReport,
  initialSaved = false,
}) => {
  const { currentUser } = useAuth();
  const [isSaved, setIsSaved] = useState(initialSaved);
  const [saving, setSaving] = useState(false);
  const [showMenu, setShowMenu] = useState(false);

  const handleToggleSave = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!currentUser) return;
    setSaving(true);
    try {
      const saved = await toggleSaveQuestion(question.id, currentUser.uid);
      setIsSaved(saved);
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  const handleShare = async (e: React.MouseEvent) => {
    e.stopPropagation();
    const shareData = {
      title: question.title,
      text: question.body.slice(0, 100),
      url: window.location.href,
    };
    if (navigator.share) {
      try {
        await navigator.share(shareData);
      } catch {
        // Ignored if cancelled
      }
    } else {
      await navigator.clipboard.writeText(window.location.href);
      alert('Link copied to clipboard');
    }
  };

  return (
    <article
      onClick={() => onSelect(question.id)}
      className="bg-white dark:bg-zinc-900 border-b border-zinc-200/70 dark:border-zinc-800/80 p-4 hover:bg-zinc-50/50 dark:hover:bg-zinc-850/50 cursor-pointer transition-colors relative"
    >
      {/* Category and Meta Header */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          {/* Category Pill */}
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              onSelectCategory?.(question.categoryId);
            }}
            className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-semibold bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-300 hover:bg-indigo-100 transition-colors"
          >
            {question.categoryName}
          </button>

          <span className="text-zinc-300 dark:text-zinc-700 text-xs">•</span>

          {/* Author */}
          <span className="text-xs text-zinc-500 dark:text-zinc-400 font-medium truncate max-w-[120px]">
            {question.isAnonymous ? 'Anonymous' : question.authorDisplayName || 'Member'}
          </span>

          <span className="text-zinc-300 dark:text-zinc-700 text-xs">•</span>

          {/* Timestamp */}
          <span className="text-xs text-zinc-400 dark:text-zinc-500">
            {formatRelativeTime(question.createdAt)}
          </span>
        </div>

        {/* Overflow Menu */}
        <div className="relative">
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              setShowMenu((prev) => !prev);
            }}
            className="p-1 rounded-md text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300 transition-colors"
          >
            <MoreVertical className="w-4 h-4" />
          </button>

          {showMenu && (
            <div
              onClick={(e) => e.stopPropagation()}
              className="absolute right-0 top-6 z-20 w-36 py-1 bg-white dark:bg-zinc-800 rounded-xl shadow-lg border border-zinc-200 dark:border-zinc-700 text-xs text-zinc-700 dark:text-zinc-200"
            >
              <button
                type="button"
                onClick={() => {
                  setShowMenu(false);
                  onOpenReport?.('question', question.id);
                }}
                className="w-full flex items-center gap-2 px-3 py-2 hover:bg-zinc-100 dark:hover:bg-zinc-700 text-rose-600 dark:text-rose-400"
              >
                <Flag className="w-3.5 h-3.5" />
                <span>Report</span>
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Title */}
      <h3 className="text-sm font-semibold text-zinc-900 dark:text-zinc-100 leading-snug mb-1.5 line-clamp-2">
        {question.title}
      </h3>

      {/* Body preview */}
      <p className="text-xs text-zinc-600 dark:text-zinc-400 line-clamp-2 leading-relaxed mb-3">
        {question.body}
      </p>

      {/* Optional Tag Pills */}
      {question.tags && question.tags.length > 0 && (
        <div className="flex flex-wrap gap-1 mb-3">
          {question.tags.slice(0, 3).map((tag, idx) => (
            <span
              key={idx}
              className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400"
            >
              #{tag}
            </span>
          ))}
        </div>
      )}

      {/* Bottom engagement row */}
      <div className="flex items-center justify-between pt-1 border-t border-zinc-100 dark:border-zinc-800/60 text-xs text-zinc-500 dark:text-zinc-400">
        <div className="flex items-center gap-4">
          {/* Answers */}
          <div className="flex items-center gap-1.5 font-medium">
            <MessageSquare className="w-3.5 h-3.5 text-zinc-400" />
            <span>{question.answerCount || 0} answers</span>
          </div>

          {/* Solved / Helpful Badge */}
          {question.helpfulAnswerId && (
            <div className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400 font-medium">
              <CheckCircle className="w-3.5 h-3.5" />
              <span>Solved</span>
            </div>
          )}

          {/* Views */}
          <div className="flex items-center gap-1">
            <Eye className="w-3.5 h-3.5 text-zinc-400" />
            <span>{formatCompactNumber(question.viewCount || 0)}</span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* Bookmark */}
          <button
            type="button"
            onClick={handleToggleSave}
            disabled={saving}
            aria-label="Save question"
            className={`p-1.5 rounded-lg transition-colors ${
              isSaved
                ? 'text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-950/40'
                : 'text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300'
            }`}
          >
            <Bookmark className={`w-3.5 h-3.5 ${isSaved ? 'fill-current' : ''}`} />
          </button>

          {/* Share */}
          <button
            type="button"
            onClick={handleShare}
            aria-label="Share question"
            className="p-1.5 rounded-lg text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300 transition-colors"
          >
            <Share2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </article>
  );
};
