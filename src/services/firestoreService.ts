import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  onSnapshot,
  increment,
  runTransaction,
  writeBatch,
} from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../firebase/config';
import {
  Category,
  Question,
  Answer,
  Vote,
  UserFollow,
  CategoryFollow,
  QuestionFollow,
  SavedQuestion,
  AppNotification,
  Report,
  Block,
  Mute,
  UserProfile,
} from '../types';
import { INITIAL_50_CATEGORIES } from './categoriesData';

// ----------------------------------------------------------------------
// CATEGORIES
// ----------------------------------------------------------------------

export async function fetchCategories(): Promise<Category[]> {
  try {
    const colRef = collection(db, 'categories');
    const snapshot = await getDocs(colRef);

    if (!snapshot.empty) {
      return snapshot.docs.map((d) => d.data() as Category);
    }

    // Read-only static application configuration
    const now = new Date().toISOString();
    return INITIAL_50_CATEGORIES.map((c) => ({
      id: c.id,
      name: c.name,
      slug: c.slug,
      description: c.description,
      icon: c.icon,
      followerCount: 0,
      questionCount: 0,
      isActive: true,
      createdAt: now,
    }));
  } catch (err) {
    const now = new Date().toISOString();
    return INITIAL_50_CATEGORIES.map((c) => ({
      id: c.id,
      name: c.name,
      slug: c.slug,
      description: c.description,
      icon: c.icon,
      followerCount: 0,
      questionCount: 0,
      isActive: true,
      createdAt: now,
    }));
  }
}

export async function followCategory(categoryId: string, uid: string): Promise<boolean> {
  const followDocId = `${categoryId}_${uid}`;
  const followRef = doc(db, 'categoryFollows', followDocId);

  try {
    const existing = await getDoc(followRef);
    if (existing.exists()) {
      // Unfollow
      await deleteDoc(followRef);
      return false;
    } else {
      // Follow
      const followData: CategoryFollow = {
        id: followDocId,
        categoryId,
        uid,
        createdAt: new Date().toISOString(),
      };
      await setDoc(followRef, followData);
      return true;
    }
  } catch (err) {
    handleFirestoreError(err, OperationType.WRITE, `categoryFollows/${followDocId}`);
  }
}

export async function getCategoryFollowedIds(uid: string): Promise<Set<string>> {
  try {
    const q = query(collection(db, 'categoryFollows'), where('uid', '==', uid));
    const snapshot = await getDocs(q);
    return new Set(snapshot.docs.map((d) => d.data().categoryId));
  } catch (err) {
    handleFirestoreError(err, OperationType.GET, 'categoryFollows');
  }
}

// ----------------------------------------------------------------------
// QUESTIONS
// ----------------------------------------------------------------------

export interface CreateQuestionParams {
  authorUid: string;
  authorDisplayName: string;
  authorPhotoUrl?: string;
  isAnonymous: boolean;
  title: string;
  body: string;
  categoryId: string;
  categoryName: string;
  tags: string[];
  imageUrl?: string;
}

export async function createQuestion(params: CreateQuestionParams): Promise<string> {
  const newDocRef = doc(collection(db, 'questions'));
  const now = new Date().toISOString();

  const question: Question = {
    id: newDocRef.id,
    authorUid: params.authorUid,
    isAnonymous: params.isAnonymous,
    authorDisplayName: params.isAnonymous ? 'Anonymous' : params.authorDisplayName,
    authorPhotoUrl: params.isAnonymous ? undefined : params.authorPhotoUrl,
    title: params.title.trim(),
    body: params.body.trim(),
    categoryId: params.categoryId,
    categoryName: params.categoryName,
    tags: params.tags,
    imageUrl: params.imageUrl || undefined,
    answerCount: 0,
    viewCount: 0,
    voteCount: 0,
    followerCount: 0,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  };

  try {
    await setDoc(newDocRef, question);
    // Server-controlled counters (user questionCount, category questionCount)
    // are updated securely via backend Cloud Function triggers
    return newDocRef.id;
  } catch (err) {
    handleFirestoreError(err, OperationType.CREATE, `questions/${newDocRef.id}`);
  }
}

export async function getQuestionById(questionId: string): Promise<Question | null> {
  try {
    const d = await getDoc(doc(db, 'questions', questionId));
    if (!d.exists()) return null;
    return d.data() as Question;
  } catch (err) {
    handleFirestoreError(err, OperationType.GET, `questions/${questionId}`);
  }
}

export async function incrementQuestionView(questionId: string): Promise<void> {
  try {
    const qRef = doc(db, 'questions', questionId);
    await updateDoc(qRef, { viewCount: increment(1) });
  } catch {
    // Non-critical, ignore silent error
  }
}

export async function fetchQuestions(options: {
  feedType: 'forYou' | 'trending' | 'new' | 'following';
  categoryId?: string;
  authorUid?: string;
  followedCategories?: string[];
  followedUsers?: string[];
  maxLimit?: number;
}): Promise<Question[]> {
  try {
    const colRef = collection(db, 'questions');
    let q;

    if (options.authorUid) {
      q = query(colRef, where('authorUid', '==', options.authorUid), limit(options.maxLimit || 30));
    } else if (options.categoryId) {
      q = query(colRef, where('categoryId', '==', options.categoryId), limit(options.maxLimit || 30));
    } else if (options.feedType === 'new') {
      q = query(colRef, limit(options.maxLimit || 30));
    } else {
      q = query(colRef, limit(options.maxLimit || 40));
    }

    const snapshot = await getDocs(q);
    let items = snapshot.docs.map((d) => d.data() as Question);

    // Client-side deterministic sorting / ranking based on feedType:
    if (options.feedType === 'new') {
      items.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    } else if (options.feedType === 'trending') {
      // Trending algorithm based on views, answers, votes and time decay
      items.sort((a, b) => {
        const scoreA = (a.viewCount || 0) * 1 + (a.answerCount || 0) * 4 + (a.voteCount || 0) * 3;
        const scoreB = (b.viewCount || 0) * 1 + (b.answerCount || 0) * 4 + (b.voteCount || 0) * 3;
        return scoreB - scoreA;
      });
    } else if (options.feedType === 'following') {
      const catSet = new Set(options.followedCategories || []);
      const userSet = new Set(options.followedUsers || []);
      items = items.filter((item) => catSet.has(item.categoryId) || userSet.has(item.authorUid));
      items.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    } else {
      // 'forYou': boost followed categories and users, else newest
      const catSet = new Set(options.followedCategories || []);
      const userSet = new Set(options.followedUsers || []);
      items.sort((a, b) => {
        let weightA = 0;
        let weightB = 0;
        if (catSet.has(a.categoryId)) weightA += 10;
        if (userSet.has(a.authorUid)) weightA += 15;
        if (catSet.has(b.categoryId)) weightB += 10;
        if (userSet.has(b.authorUid)) weightB += 15;
        const timeDiff = new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
        return (weightB - weightA) * 1000000 + timeDiff;
      });
    }

    return items;
  } catch (err) {
    handleFirestoreError(err, OperationType.GET, 'questions');
  }
}

export async function deleteQuestion(questionId: string, _categoryId: string, authorUid: string): Promise<void> {
  try {
    await deleteDoc(doc(db, 'questions', questionId));
    // Counters are maintained securely server-side
  } catch (err) {
    handleFirestoreError(err, OperationType.DELETE, `questions/${questionId}`);
  }
}

// ----------------------------------------------------------------------
// ANSWERS
// ----------------------------------------------------------------------

export interface CreateAnswerParams {
  questionId: string;
  authorUid: string;
  authorDisplayName: string;
  authorPhotoUrl?: string;
  isAnonymous: boolean;
  body: string;
  questionAuthorUid: string;
  questionTitle: string;
}

export async function createAnswer(params: CreateAnswerParams): Promise<string> {
  const newDocRef = doc(collection(db, 'answers'));
  const now = new Date().toISOString();

  const answer: Answer = {
    id: newDocRef.id,
    questionId: params.questionId,
    authorUid: params.authorUid,
    isAnonymous: params.isAnonymous,
    authorDisplayName: params.isAnonymous ? 'Anonymous' : params.authorDisplayName,
    authorPhotoUrl: params.isAnonymous ? undefined : params.authorPhotoUrl,
    body: params.body.trim(),
    voteCount: 0,
    helpfulCount: 0,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  };

  try {
    await setDoc(newDocRef, answer);
    // Question answerCount, user answerCount, reputation, and notifications
    // are processed atomically by Cloud Functions (onAnswerCreated)
    return newDocRef.id;
  } catch (err) {
    handleFirestoreError(err, OperationType.CREATE, `answers/${newDocRef.id}`);
  }
}

export async function fetchAnswersForQuestion(questionId: string): Promise<Answer[]> {
  try {
    const q = query(
      collection(db, 'answers'),
      where('questionId', '==', questionId),
      limit(50)
    );
    const snapshot = await getDocs(q);
    const items = snapshot.docs.map((d) => d.data() as Answer);
    items.sort((a, b) => (b.voteCount || 0) - (a.voteCount || 0));
    return items;
  } catch (err) {
    handleFirestoreError(err, OperationType.GET, `answers?questionId=${questionId}`);
  }
}

// ----------------------------------------------------------------------
// VOTES & HELPFUL
// ----------------------------------------------------------------------

export async function voteAnswer(
  answerId: string,
  questionId: string,
  uid: string,
  voteType: 1 | -1,
  answerAuthorUid: string
): Promise<{ newVoteCount: number; currentVote: number }> {
  const voteDocId = `${answerId}_${uid}`;
  const voteRef = doc(db, 'votes', voteDocId);
  const answerRef = doc(db, 'answers', answerId);

  try {
    return await runTransaction(db, async (txn) => {
      const voteDoc = await txn.get(voteRef);
      const answerDoc = await txn.get(answerRef);

      if (!answerDoc.exists()) {
        throw new Error('Answer not found');
      }

      const answerData = answerDoc.data() as Answer;
      let currentScore = answerData.voteCount || 0;
      let userExistingVote = 0;

      if (voteDoc.exists()) {
        const existingData = voteDoc.data() as Vote;
        userExistingVote = existingData.voteType;

        if (userExistingVote === voteType) {
          // User tapped same button -> remove vote
          txn.delete(voteRef);
          currentScore -= voteType;
          txn.update(answerRef, { voteCount: currentScore });
          return { newVoteCount: currentScore, currentVote: 0 };
        } else {
          // User switched vote (e.g. from -1 to +1: delta = +2)
          const delta = voteType - userExistingVote;
          txn.update(voteRef, { voteType, createdAt: new Date().toISOString() });
          currentScore += delta;
          txn.update(answerRef, { voteCount: currentScore });
          return { newVoteCount: currentScore, currentVote: voteType };
        }
      } else {
        // New vote
        const newVote: Vote = {
          id: voteDocId,
          answerId,
          questionId,
          uid,
          voteType,
          createdAt: new Date().toISOString(),
        };
        txn.set(voteRef, newVote);
        currentScore += voteType;
        txn.update(answerRef, { voteCount: currentScore });

        // Update answer author's reputation
        const userRef = doc(db, 'users', answerAuthorUid);
        txn.update(userRef, { reputation: increment(voteType === 1 ? 5 : -2) });

        return { newVoteCount: currentScore, currentVote: voteType };
      }
    });
  } catch (err) {
    handleFirestoreError(err, OperationType.WRITE, `votes/${voteDocId}`);
  }
}

export async function getUserVoteForAnswer(answerId: string, uid: string): Promise<number> {
  try {
    const voteRef = doc(db, 'votes', `${answerId}_${uid}`);
    const snap = await getDoc(voteRef);
    if (snap.exists()) {
      return (snap.data() as Vote).voteType;
    }
    return 0;
  } catch {
    return 0;
  }
}

export async function markAnswerHelpful(
  questionId: string,
  answerId: string,
  answerAuthorUid: string,
  questionAuthorUid: string
): Promise<boolean> {
  const helpfulDocId = `${answerId}_${questionAuthorUid}`;
  const helpfulRef = doc(db, 'helpfulVotes', helpfulDocId);
  const answerRef = doc(db, 'answers', answerId);
  const questionRef = doc(db, 'questions', questionId);

  try {
    const snap = await getDoc(helpfulRef);
    if (snap.exists()) {
      // Unmark helpful
      await deleteDoc(helpfulRef);
      await updateDoc(answerRef, { isHelpful: false });
      return false;
    } else {
      // Mark helpful
      await setDoc(helpfulRef, {
        id: helpfulDocId,
        answerId,
        questionId,
        uid: questionAuthorUid,
        createdAt: new Date().toISOString(),
      });
      await updateDoc(answerRef, { isHelpful: true });
      // Helpful reputation (+15) and notification are triggered by Cloud Functions (onAnswerHelpfulMarked)
      return true;
    }
  } catch (err) {
    handleFirestoreError(err, OperationType.WRITE, `helpfulVotes/${helpfulDocId}`);
  }
}

// ----------------------------------------------------------------------
// FOLLOWS & SAVES
// ----------------------------------------------------------------------

export async function toggleFollowUser(targetUid: string, followerUid: string): Promise<boolean> {
  const followId = `${targetUid}_${followerUid}`;
  const followRef = doc(db, 'follows', followId);

  try {
    const snap = await getDoc(followRef);
    if (snap.exists()) {
      await deleteDoc(followRef);
      return false;
    } else {
      const followData: UserFollow = {
        id: followId,
        targetUid,
        followerUid,
        createdAt: new Date().toISOString(),
      };
      await setDoc(followRef, followData);
      return true;
    }
  } catch (err) {
    handleFirestoreError(err, OperationType.WRITE, `follows/${followId}`);
  }
}

export async function isUserFollowing(targetUid: string, followerUid: string): Promise<boolean> {
  try {
    const snap = await getDoc(doc(db, 'follows', `${targetUid}_${followerUid}`));
    return snap.exists();
  } catch {
    return false;
  }
}

export async function toggleSaveQuestion(questionId: string, uid: string): Promise<boolean> {
  const saveId = `${questionId}_${uid}`;
  const saveRef = doc(db, 'savedQuestions', saveId);

  try {
    const snap = await getDoc(saveRef);
    if (snap.exists()) {
      await deleteDoc(saveRef);
      return false;
    } else {
      const savedData: SavedQuestion = {
        id: saveId,
        questionId,
        uid,
        createdAt: new Date().toISOString(),
      };
      await setDoc(saveRef, savedData);
      return true;
    }
  } catch (err) {
    handleFirestoreError(err, OperationType.WRITE, `savedQuestions/${saveId}`);
  }
}

export async function isQuestionSaved(questionId: string, uid: string): Promise<boolean> {
  try {
    const snap = await getDoc(doc(db, 'savedQuestions', `${questionId}_${uid}`));
    return snap.exists();
  } catch {
    return false;
  }
}

export async function fetchSavedQuestions(uid: string): Promise<Question[]> {
  try {
    const q = query(collection(db, 'savedQuestions'), where('uid', '==', uid), limit(50));
    const snap = await getDocs(q);
    const questionIds = snap.docs.map((d) => d.data().questionId as string);

    if (questionIds.length === 0) return [];

    const questions: Question[] = [];
    for (const qId of questionIds) {
      const qDoc = await getDoc(doc(db, 'questions', qId));
      if (qDoc.exists()) {
        questions.push(qDoc.data() as Question);
      }
    }
    return questions;
  } catch (err) {
    handleFirestoreError(err, OperationType.GET, 'savedQuestions');
  }
}

// ----------------------------------------------------------------------
// NOTIFICATIONS
// ----------------------------------------------------------------------

export async function sendNotification(params: {
  recipientUid: string;
  senderUid: string;
  senderName: string;
  type: AppNotification['type'];
  title: string;
  body: string;
  targetType: 'question' | 'answer' | 'user' | 'category';
  targetId: string;
}): Promise<void> {
  if (params.recipientUid === params.senderUid) return;

  const notifRef = doc(collection(db, 'notifications'));
  const notification: AppNotification = {
    id: notifRef.id,
    recipientUid: params.recipientUid,
    senderUid: params.senderUid,
    senderName: params.senderName,
    type: params.type,
    title: params.title,
    body: params.body,
    targetType: params.targetType,
    targetId: params.targetId,
    isRead: false,
    createdAt: new Date().toISOString(),
  };

  try {
    await setDoc(notifRef, notification);
  } catch {
    // Non-blocking notification fail
  }
}

export async function fetchUserNotifications(recipientUid: string): Promise<AppNotification[]> {
  try {
    const q = query(
      collection(db, 'notifications'),
      where('recipientUid', '==', recipientUid),
      limit(40)
    );
    const snap = await getDocs(q);
    const items = snap.docs.map((d) => d.data() as AppNotification);
    items.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    return items;
  } catch (err) {
    handleFirestoreError(err, OperationType.GET, 'notifications');
  }
}

export async function markNotificationAsRead(notificationId: string): Promise<void> {
  try {
    await updateDoc(doc(db, 'notifications', notificationId), {
      isRead: true,
      readAt: new Date().toISOString(),
    });
  } catch (err) {
    handleFirestoreError(err, OperationType.UPDATE, `notifications/${notificationId}`);
  }
}

export async function markAllNotificationsAsRead(recipientUid: string): Promise<void> {
  try {
    const notifs = await fetchUserNotifications(recipientUid);
    const batch = writeBatch(db);
    const now = new Date().toISOString();
    for (const n of notifs) {
      if (!n.isRead) {
        batch.update(doc(db, 'notifications', n.id), {
          isRead: true,
          readAt: now,
        });
      }
    }
    await batch.commit();
  } catch (err) {
    handleFirestoreError(err, OperationType.UPDATE, 'notifications');
  }
}

// ----------------------------------------------------------------------
// MODERATION & SAFETY (Rule 27, 28, 29)
// ----------------------------------------------------------------------

export async function submitReport(params: {
  reporterUid: string;
  targetType: 'question' | 'answer' | 'user';
  targetId: string;
  reason: Report['reason'];
  details?: string;
}): Promise<void> {
  const reportRef = doc(collection(db, 'reports'));
  const report: Report = {
    id: reportRef.id,
    reporterUid: params.reporterUid,
    targetType: params.targetType,
    targetId: params.targetId,
    reason: params.reason,
    details: params.details?.trim() || '',
    status: 'pending',
    createdAt: new Date().toISOString(),
  };

  try {
    await setDoc(reportRef, report);
  } catch (err) {
    handleFirestoreError(err, OperationType.CREATE, `reports/${reportRef.id}`);
  }
}

export async function blockUser(blockerUid: string, blockedUid: string): Promise<void> {
  const blockId = `${blockedUid}_${blockerUid}`;
  const blockRef = doc(db, 'blocks', blockId);
  const blockData: Block = {
    id: blockId,
    blockerUid,
    blockedUid,
    createdAt: new Date().toISOString(),
  };

  try {
    await setDoc(blockRef, blockData);
  } catch (err) {
    handleFirestoreError(err, OperationType.WRITE, `blocks/${blockId}`);
  }
}

export async function muteUser(muterUid: string, mutedUid: string): Promise<void> {
  const muteId = `${mutedUid}_${muterUid}`;
  const muteRef = doc(db, 'mutes', muteId);
  const muteData: Mute = {
    id: muteId,
    muterUid,
    mutedUid,
    createdAt: new Date().toISOString(),
  };

  try {
    await setDoc(muteRef, muteData);
  } catch (err) {
    handleFirestoreError(err, OperationType.WRITE, `mutes/${muteId}`);
  }
}

export async function getBlockedAndMutedUserIds(uid: string): Promise<Set<string>> {
  try {
    const blockedQuery = query(collection(db, 'blocks'), where('blockerUid', '==', uid));
    const mutedQuery = query(collection(db, 'mutes'), where('muterUid', '==', uid));

    const [blockedSnap, mutedSnap] = await Promise.all([
      getDocs(blockedQuery),
      getDocs(mutedQuery),
    ]);

    const ids = new Set<string>();
    blockedSnap.docs.forEach((d) => ids.add(d.data().blockedUid));
    mutedSnap.docs.forEach((d) => ids.add(d.data().mutedUid));
    return ids;
  } catch {
    return new Set<string>();
  }
}

// ----------------------------------------------------------------------
// USER PROFILE FETCH / UPDATE
// ----------------------------------------------------------------------

export async function getUserProfile(uid: string): Promise<UserProfile | null> {
  try {
    const snap = await getDoc(doc(db, 'users', uid));
    if (!snap.exists()) return null;
    return snap.data() as UserProfile;
  } catch (err) {
    handleFirestoreError(err, OperationType.GET, `users/${uid}`);
  }
}

export async function updateUserProfile(
  uid: string,
  data: Partial<Pick<UserProfile, 'displayName' | 'username' | 'bio' | 'photoUrl'>>
): Promise<void> {
  try {
    const userRef = doc(db, 'users', uid);
    await updateDoc(userRef, {
      ...data,
      updatedAt: new Date().toISOString(),
    });
  } catch (err) {
    handleFirestoreError(err, OperationType.UPDATE, `users/${uid}`);
  }
}
