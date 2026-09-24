import React, { useState, useEffect } from 'react';
import {
  Settings,
  Edit3,
  LogOut,
  Award,
  HelpCircle,
  MessageSquare,
  Bookmark,
  Users,
  Calendar,
  X,
  Check,
  AlertCircle,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { Question } from '../../types';
import { fetchQuestions, fetchSavedQuestions } from '../../services/firestoreService';
import { QuestionCard } from '../feed/QuestionCard';
import { EmptyState } from '../common/EmptyState';

interface ProfileViewProps {
  onSelectQuestion: (questionId: string) => void;
  onOpenSettings: () => void;
  onOpenAuth: () => void;
}

export const ProfileView: React.FC<ProfileViewProps> = ({
  onSelectQuestion,
  onOpenSettings,
  onOpenAuth,
}) => {
  const { currentUser, userProfile, signOut, updateProfileDetails } = useAuth();
  const [activeTab, setActiveTab] = useState<'questions' | 'saved'>('questions');
  const [myQuestions, setMyQuestions] = useState<Question[]>([]);
  const [savedQuestions, setSavedQuestions] = useState<Question[]>([]);
  const [loadingContent, setLoadingContent] = useState(false);

  // Edit profile state
  const [isEditing, setIsEditing] = useState(false);
  const [editName, setEditName] = useState('');
  const [editUsername, setEditUsername] = useState('');
  const [editBio, setEditBio] = useState('');
  const [editPhotoUrl, setEditPhotoUrl] = useState('');
  const [updating, setUpdating] = useState(false);
  const [editError, setEditError] = useState<string | null>(null);

  useEffect(() => {
    if (currentUser) {
      setLoadingContent(true);
      Promise.all([
        fetchQuestions({ feedType: 'new', authorUid: currentUser.uid }),
        fetchSavedQuestions(currentUser.uid),
      ])
        .then(([q, s]) => {
          setMyQuestions(q);
          setSavedQuestions(s);
        })
        .catch(console.error)
        .finally(() => setLoadingContent(false));
    }
  }, [currentUser]);

  const handleOpenEdit = () => {
    if (!userProfile) return;
    setEditName(userProfile.displayName || '');
    setEditUsername(userProfile.username || '');
    setEditBio(userProfile.bio || '');
    setEditPhotoUrl(userProfile.photoUrl || '');
    setEditError(null);
    setIsEditing(true);
  };

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setEditError(null);

    if (!editName.trim()) {
      setEditError('Display name is required.');
      return;
    }

    setUpdating(true);
    try {
      await updateProfileDetails({
        displayName: editName.trim(),
        username: editUsername.trim().toLowerCase().replace(/[^a-z0-9_]/g, ''),
        bio: editBio.trim(),
        photoUrl: editPhotoUrl.trim() || undefined,
      });
      setIsEditing(false);
    } catch (err: any) {
      console.error(err);
      setEditError(err.message || 'Failed to update profile.');
    } finally {
      setUpdating(false);
    }
  };

  if (!currentUser || !userProfile) {
    return (
      <EmptyState
        icon={Users}
        title="Sign in to view your profile"
        description="Track your questions, manage saved discussions, and view your community reputation."
        actionText="Sign In"
        onAction={onOpenAuth}
      />
    );
  }

  return (
    <div className="flex flex-col flex-1 pb-20">
      {/* Header Bar */}
      <div className="sticky top-[49px] z-20 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-md border-b border-zinc-200/80 dark:border-zinc-800 px-4 py-2.5 flex items-center justify-between">
        <h2 className="text-sm font-bold text-zinc-900 dark:text-zinc-100">
          @{userProfile.username}
        </h2>
        <div className="flex items-center gap-1">
          <button
            onClick={onOpenSettings}
            className="p-1.5 rounded-lg text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
          >
            <Settings className="w-4 h-4" />
          </button>
          <button
            onClick={signOut}
            title="Sign Out"
            className="p-1.5 rounded-lg text-zinc-500 hover:text-rose-600 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Profile Overview Card */}
      <div className="p-4 bg-white dark:bg-zinc-900 border-b border-zinc-200/80 dark:border-zinc-800">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            {userProfile.photoUrl ? (
              <img
                src={userProfile.photoUrl}
                alt={userProfile.displayName}
                className="w-14 h-14 rounded-2xl object-cover ring-2 ring-indigo-500/20 shadow-xs"
              />
            ) : (
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center text-white text-xl font-bold shadow-xs">
                {userProfile.displayName.charAt(0).toUpperCase()}
              </div>
            )}
            <div>
              <h1 className="text-base font-bold text-zinc-900 dark:text-zinc-100">
                {userProfile.displayName}
              </h1>
              <p className="text-xs text-zinc-400">@{userProfile.username}</p>
              <div className="flex items-center gap-1 mt-1 text-[11px] font-semibold text-indigo-600 dark:text-indigo-400">
                <Award className="w-3.5 h-3.5" />
                <span>{userProfile.reputation || 0} Reputation</span>
              </div>
            </div>
          </div>

          <button
            onClick={handleOpenEdit}
            className="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-800 text-xs font-semibold text-zinc-700 dark:text-zinc-300 transition-colors"
          >
            <Edit3 className="w-3.5 h-3.5" />
            <span>Edit</span>
          </button>
        </div>

        {userProfile.bio && (
          <p className="text-xs text-zinc-600 dark:text-zinc-400 mt-3 leading-relaxed">
            {userProfile.bio}
          </p>
        )}

        {/* Stats Strip */}
        <div className="grid grid-cols-3 gap-2 mt-4 pt-4 border-t border-zinc-100 dark:border-zinc-800/80 text-center">
          <div className="p-2 rounded-xl bg-zinc-50 dark:bg-zinc-800/60">
            <span className="block text-sm font-bold text-zinc-900 dark:text-zinc-100">
              {userProfile.questionCount || myQuestions.length}
            </span>
            <span className="text-[10px] text-zinc-400">Questions</span>
          </div>
          <div className="p-2 rounded-xl bg-zinc-50 dark:bg-zinc-800/60">
            <span className="block text-sm font-bold text-zinc-900 dark:text-zinc-100">
              {userProfile.answerCount || 0}
            </span>
            <span className="text-[10px] text-zinc-400">Answers</span>
          </div>
          <div className="p-2 rounded-xl bg-zinc-50 dark:bg-zinc-800/60">
            <span className="block text-sm font-bold text-zinc-900 dark:text-zinc-100">
              {userProfile.followersCount || 0}
            </span>
            <span className="text-[10px] text-zinc-400">Followers</span>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-zinc-200/80 dark:border-zinc-800 bg-white dark:bg-zinc-900">
        <button
          onClick={() => setActiveTab('questions')}
          className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-semibold border-b-2 transition-colors ${
            activeTab === 'questions'
              ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400'
              : 'border-transparent text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200'
          }`}
        >
          <HelpCircle className="w-3.5 h-3.5" />
          <span>My Questions ({myQuestions.length})</span>
        </button>

        <button
          onClick={() => setActiveTab('saved')}
          className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-semibold border-b-2 transition-colors ${
            activeTab === 'saved'
              ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400'
              : 'border-transparent text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-200'
          }`}
        >
          <Bookmark className="w-3.5 h-3.5" />
          <span>Saved ({savedQuestions.length})</span>
        </button>
      </div>

      {/* Tab Content */}
      <div className="flex-1">
        {loadingContent ? (
          <div className="p-4 space-y-3">
            {[1, 2].map((i) => (
              <div
                key={i}
                className="h-20 bg-white dark:bg-zinc-900 rounded-xl animate-pulse p-4 border border-zinc-200/60 dark:border-zinc-800/60"
              />
            ))}
          </div>
        ) : activeTab === 'questions' ? (
          myQuestions.length === 0 ? (
            <EmptyState
              icon={HelpCircle}
              title="No questions yet"
              description="Questions you ask will appear on your public profile."
            />
          ) : (
            <div className="divide-y divide-zinc-150 dark:divide-zinc-800/80">
              {myQuestions.map((q) => (
                <QuestionCard key={q.id} question={q} onSelect={onSelectQuestion} />
              ))}
            </div>
          )
        ) : savedQuestions.length === 0 ? (
          <EmptyState
            icon={Bookmark}
            title="No saved questions"
            description="Questions you bookmark for later will be organized here."
          />
        ) : (
          <div className="divide-y divide-zinc-150 dark:divide-zinc-800/80">
            {savedQuestions.map((q) => (
              <QuestionCard
                key={q.id}
                question={q}
                onSelect={onSelectQuestion}
                initialSaved={true}
              />
            ))}
          </div>
        )}
      </div>

      {/* Edit Profile Modal */}
      {isEditing && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-3 bg-black/60 backdrop-blur-xs transition-opacity">
          <div className="relative w-full max-w-sm rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 p-5 shadow-2xl">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-bold text-zinc-900 dark:text-zinc-100">
                Edit Profile
              </h3>
              <button
                onClick={() => setIsEditing(false)}
                className="p-1 text-zinc-400 hover:text-zinc-600 rounded-full"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {editError && (
              <div className="mb-3 flex items-center gap-2 p-2.5 rounded-xl bg-rose-50 text-rose-600 text-xs border border-rose-200">
                <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                <span>{editError}</span>
              </div>
            )}

            <form onSubmit={handleSaveProfile} className="space-y-3">
              <div>
                <label className="block text-[11px] font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                  Display Name
                </label>
                <input
                  type="text"
                  required
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="w-full px-3 py-2 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
                />
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                  Username Handle
                </label>
                <input
                  type="text"
                  required
                  value={editUsername}
                  onChange={(e) => setEditUsername(e.target.value)}
                  className="w-full px-3 py-2 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
                />
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                  Bio
                </label>
                <textarea
                  rows={3}
                  maxLength={300}
                  value={editBio}
                  onChange={(e) => setEditBio(e.target.value)}
                  placeholder="Share a short bio..."
                  className="w-full px-3 py-2 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 resize-none"
                />
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                  Avatar Image URL
                </label>
                <input
                  type="url"
                  value={editPhotoUrl}
                  onChange={(e) => setEditPhotoUrl(e.target.value)}
                  placeholder="https://example.com/avatar.jpg"
                  className="w-full px-3 py-2 text-xs rounded-xl bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
                />
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsEditing(false)}
                  className="px-3 py-1.5 rounded-xl text-xs font-semibold text-zinc-500 hover:bg-zinc-100 dark:hover:bg-zinc-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={updating}
                  className="px-4 py-1.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold disabled:opacity-50"
                >
                  {updating ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
