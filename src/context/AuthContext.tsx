import React, { createContext, useContext, useEffect, useState } from 'react';
import {
  User,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInWithPopup,
  signOut as firebaseSignOut,
  sendPasswordResetEmail,
  updateProfile,
} from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { auth, db, googleProvider, testFirestoreConnection } from '../firebase/config';
import { UserProfile } from '../types';

interface AuthContextType {
  currentUser: User | null;
  userProfile: UserProfile | null;
  loading: boolean;
  signInEmail: (email: string, pass: string) => Promise<void>;
  signUpEmail: (name: string, email: string, pass: string) => Promise<void>;
  signInGoogle: () => Promise<void>;
  sendResetEmail: (email: string) => Promise<void>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  updateProfileDetails: (data: { displayName?: string; bio?: string; username?: string; photoUrl?: string }) => Promise<void>;
  isDarkMode: boolean;
  toggleDarkMode: () => void;
  isDeviceFrame: boolean;
  toggleDeviceFrame: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [isDarkMode, setIsDarkMode] = useState<boolean>(() => {
    return localStorage.getItem('openask_theme') === 'dark';
  });
  const [isDeviceFrame, setIsDeviceFrame] = useState<boolean>(() => {
    return window.innerWidth > 900;
  });

  const toggleDarkMode = () => {
    setIsDarkMode((prev) => {
      const next = !prev;
      localStorage.setItem('openask_theme', next ? 'dark' : 'light');
      if (next) {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
      return next;
    });
  };

  const toggleDeviceFrame = () => {
    setIsDeviceFrame((prev) => !prev);
  };

  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDarkMode]);

  // Boot test
  useEffect(() => {
    testFirestoreConnection();
  }, []);

  const loadUserProfile = async (user: User): Promise<UserProfile | null> => {
    try {
      const docRef = doc(db, 'users', user.uid);
      const snap = await getDoc(docRef);

      if (snap.exists()) {
        return snap.data() as UserProfile;
      } else {
        // Create initial user profile
        const baseUsername = (user.email?.split('@')[0] || 'user')
          .replace(/[^a-zA-Z0-9_]/g, '')
          .slice(0, 15);
        const randomSuffix = Math.floor(1000 + Math.random() * 9000);
        const username = `${baseUsername}_${randomSuffix}`;
        const now = new Date().toISOString();

        const newProfile: UserProfile = {
          uid: user.uid,
          displayName: user.displayName || baseUsername,
          username,
          email: user.email || '',
          photoUrl: user.photoURL || undefined,
          bio: '',
          createdAt: now,
          updatedAt: now,
          followersCount: 0,
          followingCount: 0,
          questionCount: 0,
          answerCount: 0,
          reputation: 0,
          isActive: true,
          isBanned: false,
        };

        await setDoc(docRef, newProfile);
        return newProfile;
      }
    } catch (err) {
      console.error('Failed to load user profile from Firestore:', err);
      return null;
    }
  };

  const refreshProfile = async () => {
    if (currentUser) {
      const profile = await loadUserProfile(currentUser);
      setUserProfile(profile);
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user);
      if (user) {
        const profile = await loadUserProfile(user);
        setUserProfile(profile);
      } else {
        setUserProfile(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const signInEmail = async (email: string, pass: string) => {
    const cred = await signInWithEmailAndPassword(auth, email.trim(), pass);
    const profile = await loadUserProfile(cred.user);
    setUserProfile(profile);
  };

  const signUpEmail = async (name: string, email: string, pass: string) => {
    const cred = await createUserWithEmailAndPassword(auth, email.trim(), pass);
    if (name.trim()) {
      await updateProfile(cred.user, { displayName: name.trim() });
    }
    const profile = await loadUserProfile(cred.user);
    setUserProfile(profile);
  };

  const signInGoogle = async () => {
    const cred = await signInWithPopup(auth, googleProvider);
    const profile = await loadUserProfile(cred.user);
    setUserProfile(profile);
  };

  const sendResetEmail = async (email: string) => {
    await sendPasswordResetEmail(auth, email.trim());
  };

  const signOut = async () => {
    await firebaseSignOut(auth);
    setUserProfile(null);
  };

  const updateProfileDetails = async (data: {
    displayName?: string;
    bio?: string;
    username?: string;
    photoUrl?: string;
  }) => {
    if (!currentUser) return;
    const userRef = doc(db, 'users', currentUser.uid);
    const updates: Partial<UserProfile> = {
      ...data,
      updatedAt: new Date().toISOString(),
    };
    await setDoc(userRef, updates, { merge: true });

    if (data.displayName || data.photoUrl) {
      await updateProfile(currentUser, {
        displayName: data.displayName || currentUser.displayName,
        photoURL: data.photoUrl || currentUser.photoURL,
      });
    }

    await refreshProfile();
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        userProfile,
        loading,
        signInEmail,
        signUpEmail,
        signInGoogle,
        sendResetEmail,
        signOut,
        refreshProfile,
        updateProfileDetails,
        isDarkMode,
        toggleDarkMode,
        isDeviceFrame,
        toggleDeviceFrame,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
