/**
 * OpenAsk Master Data Models & Types
 */

export interface UserProfile {
  uid: string;
  displayName: string;
  username: string;
  email: string;
  photoUrl?: string;
  bio?: string;
  createdAt: string;
  updatedAt: string;
  followersCount: number;
  followingCount: number;
  questionCount: number;
  answerCount: number;
  reputation: number;
  isActive: boolean;
  isBanned: boolean;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  description: string;
  icon: string;
  followerCount: number;
  questionCount: number;
  isActive: boolean;
  createdAt: string;
}

export interface Question {
  id: string;
  authorUid: string;
  isAnonymous: boolean;
  authorDisplayName?: string;
  authorPhotoUrl?: string;
  title: string;
  body: string;
  categoryId: string;
  categoryName: string;
  tags: string[];
  imageUrl?: string;
  answerCount: number;
  viewCount: number;
  voteCount: number;
  followerCount: number;
  helpfulAnswerId?: string;
  status: 'active' | 'closed' | 'hidden';
  createdAt: string;
  updatedAt: string;
}

export interface Answer {
  id: string;
  questionId: string;
  authorUid: string;
  isAnonymous: boolean;
  authorDisplayName?: string;
  authorPhotoUrl?: string;
  body: string;
  voteCount: number;
  helpfulCount: number;
  isHelpful?: boolean;
  status: 'active' | 'hidden';
  createdAt: string;
  updatedAt: string;
}

export interface Comment {
  id: string;
  targetType: 'question' | 'answer';
  targetId: string;
  questionId: string;
  authorUid: string;
  isAnonymous: boolean;
  authorDisplayName?: string;
  authorPhotoUrl?: string;
  text: string;
  createdAt: string;
}

export interface Vote {
  id: string;
  answerId: string;
  questionId: string;
  uid: string;
  voteType: 1 | -1;
  createdAt: string;
}

export interface HelpfulVote {
  id: string;
  answerId: string;
  questionId: string;
  uid: string;
  createdAt: string;
}

export interface UserFollow {
  id: string;
  targetUid: string;
  followerUid: string;
  createdAt: string;
}

export interface CategoryFollow {
  id: string;
  categoryId: string;
  uid: string;
  createdAt: string;
}

export interface QuestionFollow {
  id: string;
  questionId: string;
  uid: string;
  createdAt: string;
}

export interface SavedQuestion {
  id: string;
  questionId: string;
  uid: string;
  createdAt: string;
}

export type NotificationType =
  | 'answer'
  | 'vote'
  | 'helpful'
  | 'follow'
  | 'category_question'
  | 'question_answer'
  | 'system';

export interface AppNotification {
  id: string;
  recipientUid: string;
  senderUid: string;
  senderName: string;
  type: NotificationType;
  title: string;
  body: string;
  targetType: 'question' | 'answer' | 'user' | 'category';
  targetId: string;
  isRead: boolean;
  createdAt: string;
}

export type ReportReason =
  | 'Spam'
  | 'Harassment'
  | 'Hate'
  | 'Sexual content'
  | 'Violence'
  | 'Illegal content'
  | 'Misinformation'
  | 'Self-harm content'
  | 'Copyright'
  | 'Other';

export interface Report {
  id: string;
  reporterUid: string;
  targetType: 'question' | 'answer' | 'user';
  targetId: string;
  reason: ReportReason;
  details?: string;
  status: 'pending' | 'reviewed' | 'dismissed' | 'actioned';
  createdAt: string;
}

export interface Block {
  id: string;
  blockerUid: string;
  blockedUid: string;
  createdAt: string;
}

export interface Mute {
  id: string;
  muterUid: string;
  mutedUid: string;
  createdAt: string;
}
