import React, { useState, useEffect } from 'react';
import { X, Send, EyeOff, Globe, Tag, AlertCircle, Image as ImageIcon } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { Category } from '../../types';
import { fetchCategories, createQuestion } from '../../services/firestoreService';

interface AskQuestionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onQuestionCreated: (questionId: string) => void;
  defaultCategoryId?: string;
}

export const AskQuestionModal: React.FC<AskQuestionModalProps> = ({
  isOpen,
  onClose,
  onQuestionCreated,
  defaultCategoryId,
}) => {
  const { currentUser, userProfile } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [categoryId, setCategoryId] = useState(defaultCategoryId || '');
  const [tagsInput, setTagsInput] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [isAnonymous, setIsAnonymous] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      fetchCategories()
        .then((cats) => {
          setCategories(cats);
          if (!categoryId && cats.length > 0) {
            setCategoryId(defaultCategoryId || cats[0].id);
          }
        })
        .catch(console.error);
    }
  }, [isOpen, defaultCategoryId]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!currentUser) {
      setError('You must be signed in to ask a question.');
      return;
    }
    if (title.trim().length < 8) {
      setError('Question title must be at least 8 characters long.');
      return;
    }
    if (body.trim().length < 15) {
      setError('Please add more detail in the body (at least 15 characters).');
      return;
    }
    if (!categoryId) {
      setError('Please select a valid category.');
      return;
    }

    const selectedCategory = categories.find((c) => c.id === categoryId);
    if (!selectedCategory) {
      setError('Selected category was not found.');
      return;
    }

    const parsedTags = tagsInput
      .split(',')
      .map((t) => t.trim().toLowerCase().replace(/[^a-z0-9_-]/g, ''))
      .filter((t) => t.length > 0)
      .slice(0, 5);

    setLoading(true);
    try {
      const qId = await createQuestion({
        authorUid: currentUser.uid,
        authorDisplayName: userProfile?.displayName || currentUser.displayName || 'Member',
        authorPhotoUrl: userProfile?.photoUrl || currentUser.photoURL || undefined,
        isAnonymous,
        title: title.trim(),
        body: body.trim(),
        categoryId: selectedCategory.id,
        categoryName: selectedCategory.name,
        tags: parsedTags,
        imageUrl: imageUrl.trim() || undefined,
      });

      // Reset
      setTitle('');
      setBody('');
      setTagsInput('');
      setImageUrl('');
      setIsAnonymous(false);

      onQuestionCreated(qId);
      onClose();
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to submit question. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-xs transition-opacity animate-in fade-in duration-200">
      <div className="relative w-full max-w-md max-h-[92vh] flex flex-col rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="px-5 py-3.5 border-b border-zinc-200/80 dark:border-zinc-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-zinc-900 dark:text-zinc-100">
              Ask the World
            </h2>
            <span className="text-[10px] uppercase font-semibold px-2 py-0.5 rounded-full bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400">
              OpenAsk
            </span>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200 rounded-full hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Scrollable Form Body */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-5 space-y-4">
          {error && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 text-xs border border-rose-200 dark:border-rose-900/50">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Privacy Toggle: Public vs Anonymous */}
          <div className="flex rounded-2xl bg-zinc-100 dark:bg-zinc-800 p-1 border border-zinc-200/60 dark:border-zinc-700/60">
            <button
              type="button"
              onClick={() => setIsAnonymous(false)}
              className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-xl text-xs font-semibold transition-all ${
                !isAnonymous
                  ? 'bg-white dark:bg-zinc-900 text-zinc-900 dark:text-white shadow-xs'
                  : 'text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300'
              }`}
            >
              <Globe className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" />
              <span>Post Publicly</span>
            </button>

            <button
              type="button"
              onClick={() => setIsAnonymous(true)}
              className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-xl text-xs font-semibold transition-all ${
                isAnonymous
                  ? 'bg-white dark:bg-zinc-900 text-zinc-900 dark:text-white shadow-xs'
                  : 'text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300'
              }`}
            >
              <EyeOff className="w-3.5 h-3.5 text-amber-500" />
              <span>Post Anonymously</span>
            </button>
          </div>

          {isAnonymous && (
            <p className="text-[11px] text-amber-600 dark:text-amber-400/90 bg-amber-50 dark:bg-amber-950/30 p-2.5 rounded-xl border border-amber-200/60 dark:border-amber-900/40 leading-relaxed">
              <strong>Anonymous Posting:</strong> Your identity will be hidden from other users. OpenAsk retains your account reference internally for trust and safety.
            </p>
          )}

          {/* Category Picker */}
          <div>
            <label className="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1">
              Category
            </label>
            <select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
              className="w-full px-3 py-2 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
            >
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          {/* Title */}
          <div>
            <div className="flex justify-between items-center mb-1">
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Question Headline
              </label>
              <span className="text-[10px] text-zinc-400">{title.length}/200</span>
            </div>
            <input
              type="text"
              required
              maxLength={200}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="What is your question? Be specific and clear..."
              className="w-full px-3 py-2.5 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 font-medium"
            />
          </div>

          {/* Body */}
          <div>
            <div className="flex justify-between items-center mb-1">
              <label className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
                Details &amp; Context
              </label>
              <span className="text-[10px] text-zinc-400">{body.length}/5000</span>
            </div>
            <textarea
              required
              rows={4}
              maxLength={5000}
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="Provide background, details, constraints, or what you have tried so far..."
              className="w-full px-3 py-2.5 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 leading-relaxed resize-none"
            />
          </div>

          {/* Tags */}
          <div>
            <label className="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1">
              Tags <span className="text-zinc-400 font-normal">(optional, comma-separated)</span>
            </label>
            <div className="relative">
              <Tag className="absolute left-3 top-2.5 w-4 h-4 text-zinc-400" />
              <input
                type="text"
                value={tagsInput}
                onChange={(e) => setTagsInput(e.target.value)}
                placeholder="e.g. react, typescript, database (up to 5)"
                className="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
              />
            </div>
          </div>

          {/* Optional Image URL */}
          <div>
            <label className="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1">
              Image URL <span className="text-zinc-400 font-normal">(optional)</span>
            </label>
            <div className="relative">
              <ImageIcon className="absolute left-3 top-2.5 w-4 h-4 text-zinc-400" />
              <input
                type="url"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://example.com/diagram.png"
                className="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
              />
            </div>
          </div>
        </form>

        {/* Footer Actions */}
        <div className="p-4 border-t border-zinc-200/80 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-850/50 flex items-center justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-xs font-semibold text-zinc-600 dark:text-zinc-300 hover:bg-zinc-200/60 dark:hover:bg-zinc-800 transition-colors"
          >
            Cancel
          </button>

          <button
            type="button"
            onClick={handleSubmit}
            disabled={loading}
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 active:scale-95 text-white text-xs font-semibold transition-all shadow-sm shadow-indigo-600/20 disabled:opacity-60"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <Send className="w-3.5 h-3.5" />
                <span>Post Question</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
