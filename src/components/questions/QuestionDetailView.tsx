import React, { useState, useEffect } from 'react';
import {
  ArrowLeft,
  Share2,
  Bookmark,
  Flag,
  UserCheck,
  CheckCircle2,
  ThumbsUp,
  ThumbsDown,
  Send,
  EyeOff,
  Globe,
  MessageSquare,
  Sparkles,
} from 'lucide-react';
import { Question, Answer } from '../../types';
import { formatRelativeTime } from '../../utils/formatters';
import { useAuth } from '../../context/AuthContext';
import {
  getQuestionById,
  incrementQuestionView,
  fetchAnswersForQuestion,
  createAnswer,
  voteAnswer,
  getUserVoteForAnswer,
  markAnswerHelpful,
  toggleSaveQuestion,
  isQuestionSaved,
} from '../../services/firestoreService';

interface QuestionDetailViewProps {
  questionId: string;
  onBack: () => void;
  onSelectCategory: (categoryId: string) => void;
  onOpenReport: (targetType: 'question' | 'answer', targetId: string) => void;
  onOpenAuth: () => void;
}

export const QuestionDetailView: React.FC<QuestionDetailViewProps> = ({
  questionId,
  onBack,
  onSelectCategory,
  onOpenReport,
  onOpenAuth,
}) => {
  const { currentUser, userProfile } = useAuth();
  const [question, setQuestion] = useState<Question | null>(null);
  const [answers, setAnswers] = useState<Answer[]>([]);
  const [loading, setLoading] = useState(true);
  const [isSaved, setIsSaved] = useState(false);

  // User votes map: answerId -> 1 | -1 | 0
  const [userVotes, setUserVotes] = useState<Record<string, number>>({});

  // Answer composer state
  const [answerBody, setAnswerBody] = useState('');
  const [isAnonymousAnswer, setIsAnonymousAnswer] = useState(false);
  const [submittingAnswer, setSubmittingAnswer] = useState(false);
  const [answerError, setAnswerError] = useState<string | null>(null);

  const loadQuestionData = async () => {
    try {
      const q = await getQuestionById(questionId);
      if (q) {
        setQuestion(q);
        incrementQuestionView(questionId);
      }

      if (currentUser) {
        const saved = await isQuestionSaved(questionId, currentUser.uid);
        setIsSaved(saved);
      }

      const ans = await fetchAnswersForQuestion(questionId);
      setAnswers(ans);

      // Fetch user votes for these answers
      if (currentUser && ans.length > 0) {
        const votesMap: Record<string, number> = {};
        await Promise.all(
          ans.map(async (a) => {
            const v = await getUserVoteForAnswer(a.id, currentUser.uid);
            votesMap[a.id] = v;
          })
        );
        setUserVotes(votesMap);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadQuestionData();
  }, [questionId, currentUser]);

  const handleToggleSave = async () => {
    if (!currentUser) {
      onOpenAuth();
      return;
    }
    try {
      const saved = await toggleSaveQuestion(questionId, currentUser.uid);
      setIsSaved(saved);
    } catch (err) {
      console.error(err);
    }
  };

  const handleShare = async () => {
    if (!question) return;
    const shareData = {
      title: question.title,
      text: question.body.slice(0, 100),
      url: window.location.href,
    };
    if (navigator.share) {
      try {
        await navigator.share(shareData);
      } catch {}
    } else {
      await navigator.clipboard.writeText(window.location.href);
      alert('Link copied to clipboard');
    }
  };

  const handleVote = async (answer: Answer, voteType: 1 | -1) => {
    if (!currentUser) {
      onOpenAuth();
      return;
    }
    try {
      const result = await voteAnswer(
        answer.id,
        questionId,
        currentUser.uid,
        voteType,
        answer.authorUid
      );

      // Update state
      setUserVotes((prev) => ({ ...prev, [answer.id]: result.currentVote }));
      setAnswers((prev) =>
        prev.map((a) => (a.id === answer.id ? { ...a, voteCount: result.newVoteCount } : a))
      );
    } catch (err) {
      console.error('Vote failed:', err);
    }
  };

  const handleToggleHelpful = async (answer: Answer) => {
    if (!currentUser || !question) return;
    if (currentUser.uid !== question.authorUid) {
      return; // Only question author can mark helpful
    }

    try {
      const isNowHelpful = await markAnswerHelpful(
        questionId,
        answer.id,
        answer.authorUid,
        currentUser.uid
      );

      setQuestion((prev) =>
        prev ? { ...prev, helpfulAnswerId: isNowHelpful ? answer.id : undefined } : null
      );

      setAnswers((prev) =>
        prev.map((a) => {
          if (a.id === answer.id) {
            return {
              ...a,
              isHelpful: isNowHelpful,
              helpfulCount: (a.helpfulCount || 0) + (isNowHelpful ? 1 : -1),
            };
          }
          return a;
        })
      );
    } catch (err) {
      console.error(err);
    }
  };

  const handleSubmitAnswer = async (e: React.FormEvent) => {
    e.preventDefault();
    setAnswerError(null);

    if (!currentUser) {
      onOpenAuth();
      return;
    }
    if (answerBody.trim().length < 5) {
      setAnswerError('Answer must be at least 5 characters long.');
      return;
    }
    if (!question) return;

    setSubmittingAnswer(true);
    try {
      const ansId = await createAnswer({
        questionId,
        authorUid: currentUser.uid,
        authorDisplayName: userProfile?.displayName || currentUser.displayName || 'Member',
        authorPhotoUrl: userProfile?.photoUrl || currentUser.photoURL || undefined,
        isAnonymous: isAnonymousAnswer,
        body: answerBody.trim(),
        questionAuthorUid: question.authorUid,
        questionTitle: question.title,
      });

      const newAns: Answer = {
        id: ansId,
        questionId,
        authorUid: currentUser.uid,
        isAnonymous: isAnonymousAnswer,
        authorDisplayName: isAnonymousAnswer
          ? 'Anonymous'
          : userProfile?.displayName || currentUser.displayName || 'Member',
        authorPhotoUrl: isAnonymousAnswer
          ? undefined
          : userProfile?.photoUrl || currentUser.photoURL || undefined,
        body: answerBody.trim(),
        voteCount: 0,
        helpfulCount: 0,
        status: 'active',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      setAnswers((prev) => [newAns, ...prev]);
      setQuestion((prev) => (prev ? { ...prev, answerCount: (prev.answerCount || 0) + 1 } : null));
      setAnswerBody('');
    } catch (err: any) {
      console.error(err);
      setAnswerError(err.message || 'Failed to submit answer.');
    } finally {
      setSubmittingAnswer(false);
    }
  };

  if (loading) {
    return (
      <div className="p-4 space-y-4">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-zinc-200 dark:bg-zinc-800 animate-pulse" />
          <div className="h-4 bg-zinc-200 dark:bg-zinc-800 rounded w-1/3 animate-pulse" />
        </div>
        <div className="h-7 bg-zinc-200 dark:bg-zinc-800 rounded w-3/4 animate-pulse" />
        <div className="h-20 bg-zinc-200 dark:bg-zinc-800 rounded w-full animate-pulse" />
      </div>
    );
  }

  if (!question) {
    return (
      <div className="p-6 text-center">
        <p className="text-sm text-zinc-500 mb-4">Question not found or deleted.</p>
        <button
          onClick={onBack}
          className="px-4 py-2 rounded-xl bg-zinc-900 text-white dark:bg-white dark:text-zinc-900 text-xs font-semibold"
        >
          Return to Feed
        </button>
      </div>
    );
  }

  const isQuestionAuthor = currentUser?.uid === question.authorUid;

  return (
    <div className="flex flex-col flex-1 pb-24">
      {/* Top Header */}
      <div className="sticky top-[49px] z-20 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-md border-b border-zinc-200/80 dark:border-zinc-800 px-3 py-2 flex items-center justify-between">
        <button
          onClick={onBack}
          className="flex items-center gap-1.5 text-xs font-semibold text-zinc-700 dark:text-zinc-300 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors p-1"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </button>

        <div className="flex items-center gap-1">
          <button
            onClick={handleToggleSave}
            aria-label="Save question"
            className={`p-1.5 rounded-lg transition-colors ${
              isSaved
                ? 'text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-950/40'
                : 'text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200'
            }`}
          >
            <Bookmark className={`w-4 h-4 ${isSaved ? 'fill-current' : ''}`} />
          </button>

          <button
            onClick={handleShare}
            aria-label="Share question"
            className="p-1.5 rounded-lg text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200 transition-colors"
          >
            <Share2 className="w-4 h-4" />
          </button>

          <button
            onClick={() => onOpenReport('question', question.id)}
            aria-label="Report question"
            className="p-1.5 rounded-lg text-zinc-500 hover:text-rose-600 transition-colors"
          >
            <Flag className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Main Question Article */}
      <div className="p-4 bg-white dark:bg-zinc-900 border-b border-zinc-200/80 dark:border-zinc-800 space-y-3">
        {/* Meta & Category */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => onSelectCategory(question.categoryId)}
            className="px-2 py-0.5 rounded-md text-[11px] font-semibold bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-300"
          >
            {question.categoryName}
          </button>
          <span className="text-zinc-300 dark:text-zinc-700">•</span>
          <span className="text-xs text-zinc-500 dark:text-zinc-400 font-medium">
            {question.isAnonymous ? 'Anonymous' : question.authorDisplayName || 'Member'}
          </span>
          <span className="text-zinc-300 dark:text-zinc-700">•</span>
          <span className="text-xs text-zinc-400">
            {formatRelativeTime(question.createdAt)}
          </span>
        </div>

        {/* Title */}
        <h1 className="text-base font-bold text-zinc-900 dark:text-zinc-100 leading-snug">
          {question.title}
        </h1>

        {/* Body */}
        <p className="text-xs leading-relaxed text-zinc-700 dark:text-zinc-300 whitespace-pre-line">
          {question.body}
        </p>

        {/* Optional Image */}
        {question.imageUrl && (
          <div className="mt-2 rounded-2xl overflow-hidden border border-zinc-200 dark:border-zinc-700">
            <img
              src={question.imageUrl}
              alt="Question attachment"
              className="w-full max-h-72 object-cover"
            />
          </div>
        )}

        {/* Tags */}
        {question.tags && question.tags.length > 0 && (
          <div className="flex flex-wrap gap-1 pt-1">
            {question.tags.map((tag, i) => (
              <span
                key={i}
                className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400"
              >
                #{tag}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Answers Section Header */}
      <div className="px-4 py-2.5 bg-zinc-50/70 dark:bg-zinc-950/40 border-b border-zinc-200/80 dark:border-zinc-800 flex items-center justify-between">
        <div className="flex items-center gap-1.5 font-semibold text-xs text-zinc-800 dark:text-zinc-200">
          <MessageSquare className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" />
          <span>{answers.length} Answers</span>
        </div>
      </div>

      {/* Answers List */}
      <div className="divide-y divide-zinc-150 dark:divide-zinc-800/80">
        {answers.length === 0 ? (
          <div className="py-12 px-6 text-center text-zinc-400">
            <p className="text-xs">
              No answers yet. Share your knowledge by posting the first answer below.
            </p>
          </div>
        ) : (
          answers.map((ans) => {
            const isHelpfulAnswer = question.helpfulAnswerId === ans.id || ans.isHelpful;
            const currentVote = userVotes[ans.id] || 0;

            return (
              <div
                key={ans.id}
                className={`p-4 bg-white dark:bg-zinc-900 transition-colors ${
                  isHelpfulAnswer
                    ? 'border-l-4 border-l-emerald-500 bg-emerald-50/20 dark:bg-emerald-950/10'
                    : ''
                }`}
              >
                {/* Answer Author Header */}
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-6 h-6 rounded-full bg-zinc-200 dark:bg-zinc-700 flex items-center justify-center text-[10px] font-bold text-zinc-700 dark:text-zinc-300">
                      {ans.isAnonymous ? 'A' : ans.authorDisplayName?.charAt(0) || 'M'}
                    </div>
                    <span className="text-xs font-semibold text-zinc-900 dark:text-zinc-100">
                      {ans.isAnonymous ? 'Anonymous' : ans.authorDisplayName || 'Member'}
                    </span>
                    <span className="text-zinc-300 dark:text-zinc-700">•</span>
                    <span className="text-[11px] text-zinc-400">
                      {formatRelativeTime(ans.createdAt)}
                    </span>
                  </div>

                  {/* Helpful Badge or Author Action */}
                  <div className="flex items-center gap-1">
                    {isHelpfulAnswer && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300">
                        <CheckCircle2 className="w-3 h-3" />
                        <span>Helpful Solution</span>
                      </span>
                    )}

                    {isQuestionAuthor && !ans.isAnonymous && ans.authorUid !== currentUser?.uid && (
                      <button
                        onClick={() => handleToggleHelpful(ans)}
                        className={`text-[10px] font-semibold px-2 py-0.5 rounded-md border transition-colors ${
                          isHelpfulAnswer
                            ? 'border-emerald-500 text-emerald-600'
                            : 'border-zinc-300 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 hover:border-emerald-500 hover:text-emerald-600'
                        }`}
                      >
                        {isHelpfulAnswer ? 'Unmark' : 'Mark Helpful'}
                      </button>
                    )}

                    <button
                      onClick={() => onOpenReport('answer', ans.id)}
                      className="p-1 text-zinc-400 hover:text-rose-500"
                    >
                      <Flag className="w-3 h-3" />
                    </button>
                  </div>
                </div>

                {/* Answer Body */}
                <p className="text-xs leading-relaxed text-zinc-700 dark:text-zinc-300 whitespace-pre-line mb-3">
                  {ans.body}
                </p>

                {/* Voting & Actions */}
                <div className="flex items-center gap-3 text-xs text-zinc-500">
                  <div className="inline-flex items-center rounded-xl bg-zinc-100 dark:bg-zinc-800 p-0.5 border border-zinc-200/60 dark:border-zinc-700/60">
                    <button
                      onClick={() => handleVote(ans, 1)}
                      aria-label="Upvote"
                      className={`p-1.5 rounded-lg transition-colors ${
                        currentVote === 1
                          ? 'text-indigo-600 dark:text-indigo-400 bg-white dark:bg-zinc-700 shadow-xs'
                          : 'hover:text-zinc-900 dark:hover:text-zinc-100'
                      }`}
                    >
                      <ThumbsUp className="w-3.5 h-3.5" />
                    </button>

                    <span className="px-2 font-bold text-xs text-zinc-800 dark:text-zinc-200">
                      {ans.voteCount || 0}
                    </span>

                    <button
                      onClick={() => handleVote(ans, -1)}
                      aria-label="Downvote"
                      className={`p-1.5 rounded-lg transition-colors ${
                        currentVote === -1
                          ? 'text-rose-600 dark:text-rose-400 bg-white dark:bg-zinc-700 shadow-xs'
                          : 'hover:text-zinc-900 dark:hover:text-zinc-100'
                      }`}
                    >
                      <ThumbsDown className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Floating Answer Composer at Bottom */}
      <div className="fixed bottom-0 left-0 right-0 max-w-md mx-auto z-30 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-md border-t border-zinc-200 dark:border-zinc-800 p-3">
        {answerError && (
          <p className="text-[11px] text-rose-500 mb-1 px-1">{answerError}</p>
        )}

        <form onSubmit={handleSubmitAnswer} className="space-y-2">
          <div className="flex items-center justify-between px-1">
            <button
              type="button"
              onClick={() => setIsAnonymousAnswer((prev) => !prev)}
              className={`flex items-center gap-1 text-[11px] font-medium transition-colors ${
                isAnonymousAnswer
                  ? 'text-amber-600 dark:text-amber-400'
                  : 'text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300'
              }`}
            >
              {isAnonymousAnswer ? (
                <>
                  <EyeOff className="w-3.5 h-3.5" />
                  <span>Answering Anonymously</span>
                </>
              ) : (
                <>
                  <Globe className="w-3.5 h-3.5" />
                  <span>Answering Publicly</span>
                </>
              )}
            </button>
          </div>

          <div className="flex items-center gap-2">
            <input
              type="text"
              required
              value={answerBody}
              onChange={(e) => setAnswerBody(e.target.value)}
              placeholder="Write a clear, helpful answer..."
              className="flex-1 px-3 py-2 text-xs rounded-xl bg-zinc-100 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
            />

            <button
              type="submit"
              disabled={submittingAnswer || !answerBody.trim()}
              className="p-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 active:scale-95 text-white disabled:opacity-50 transition-all shadow-xs"
            >
              <Send className="w-3.5 h-3.5" />
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
