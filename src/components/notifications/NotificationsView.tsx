import React, { useState, useEffect } from 'react';
import {
  Bell,
  MessageSquare,
  ThumbsUp,
  CheckCircle2,
  UserPlus,
  Info,
  CheckCheck,
} from 'lucide-react';
import { AppNotification } from '../../types';
import { formatRelativeTime } from '../../utils/formatters';
import { useAuth } from '../../context/AuthContext';
import {
  fetchUserNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
} from '../../services/firestoreService';
import { EmptyState } from '../common/EmptyState';

interface NotificationsViewProps {
  onSelectQuestion: (questionId: string) => void;
  onOpenAuth: () => void;
  onRefreshBadge?: () => void;
}

export const NotificationsView: React.FC<NotificationsViewProps> = ({
  onSelectQuestion,
  onOpenAuth,
  onRefreshBadge,
}) => {
  const { currentUser } = useAuth();
  const [notifications, setNotifications] = useState<AppNotification[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (currentUser) {
      fetchUserNotifications(currentUser.uid)
        .then((items) => {
          setNotifications(items);
          onRefreshBadge?.();
        })
        .catch(console.error)
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, [currentUser]);

  const handleSelectNotification = async (n: AppNotification) => {
    if (!n.isRead) {
      await markNotificationAsRead(n.id).catch(console.error);
      setNotifications((prev) =>
        prev.map((item) => (item.id === n.id ? { ...item, isRead: true } : item))
      );
      onRefreshBadge?.();
    }
    if (n.targetType === 'question') {
      onSelectQuestion(n.targetId);
    }
  };

  const handleMarkAllRead = async () => {
    if (!currentUser) return;
    try {
      await markAllNotificationsAsRead(currentUser.uid);
      setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
      onRefreshBadge?.();
    } catch (err) {
      console.error(err);
    }
  };

  if (!currentUser) {
    return (
      <EmptyState
        icon={Bell}
        title="Sign in to view notifications"
        description="Get notified when community members answer your questions, vote, or follow your updates."
        actionText="Sign In"
        onAction={onOpenAuth}
      />
    );
  }

  const getNotificationIcon = (type: AppNotification['type']) => {
    switch (type) {
      case 'answer':
      case 'question_answer':
        return <MessageSquare className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />;
      case 'vote':
        return <ThumbsUp className="w-4 h-4 text-blue-600 dark:text-blue-400" />;
      case 'helpful':
        return <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />;
      case 'follow':
        return <UserPlus className="w-4 h-4 text-violet-600 dark:text-violet-400" />;
      default:
        return <Info className="w-4 h-4 text-zinc-500" />;
    }
  };

  return (
    <div className="flex flex-col flex-1 pb-16">
      {/* Header */}
      <div className="sticky top-[49px] z-20 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-md border-b border-zinc-200/80 dark:border-zinc-800 px-4 py-2.5 flex items-center justify-between">
        <h2 className="text-sm font-bold text-zinc-900 dark:text-zinc-100">Notifications</h2>

        {notifications.some((n) => !n.isRead) && (
          <button
            onClick={handleMarkAllRead}
            className="flex items-center gap-1 text-[11px] font-semibold text-indigo-600 dark:text-indigo-400 hover:underline"
          >
            <CheckCheck className="w-3.5 h-3.5" />
            <span>Mark all read</span>
          </button>
        )}
      </div>

      {/* Notifications Content */}
      <div className="flex-1">
        {loading ? (
          <div className="p-4 space-y-3">
            {[1, 2, 3].map((i) => (
              <div
                key={i}
                className="h-16 rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200/60 dark:border-zinc-800/60 animate-pulse p-3"
              />
            ))}
          </div>
        ) : notifications.length === 0 ? (
          <EmptyState
            icon={Bell}
            title="You're all caught up"
            description="When people interact with your questions and answers, updates will appear here."
          />
        ) : (
          <div className="divide-y divide-zinc-150 dark:divide-zinc-800/80">
            {notifications.map((n) => (
              <div
                key={n.id}
                onClick={() => handleSelectNotification(n)}
                className={`flex items-start gap-3 p-3.5 hover:bg-zinc-50 dark:hover:bg-zinc-850/50 cursor-pointer transition-colors ${
                  !n.isRead ? 'bg-indigo-50/30 dark:bg-indigo-950/20' : 'bg-white dark:bg-zinc-900'
                }`}
              >
                <div className="p-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 shrink-0 mt-0.5">
                  {getNotificationIcon(n.type)}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-1 mb-0.5">
                    <h4 className="text-xs font-semibold text-zinc-900 dark:text-zinc-100 truncate">
                      {n.title}
                    </h4>
                    <span className="text-[10px] text-zinc-400 shrink-0">
                      {formatRelativeTime(n.createdAt)}
                    </span>
                  </div>
                  <p className="text-xs text-zinc-600 dark:text-zinc-400 line-clamp-2 leading-relaxed">
                    {n.body}
                  </p>
                </div>

                {!n.isRead && (
                  <span className="w-2 h-2 rounded-full bg-indigo-600 dark:bg-indigo-400 shrink-0 mt-2" />
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
