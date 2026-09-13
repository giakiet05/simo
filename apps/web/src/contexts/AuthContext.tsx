import React, { createContext, useContext, useEffect, useState } from 'react';
import { api, clearAuthSession, getAuthToken, setAuthSession, type UserProfile } from '../services/api';
import { syncService } from '../services/syncService';
import { liveSyncService } from '../services/liveSyncService';

interface AuthContextType {
  user: UserProfile | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  loginWithGoogle: (idToken: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    const initializeAuth = async () => {
      const storedToken = getAuthToken();
      const storedUser = localStorage.getItem('simo_user_profile');

      if (storedToken && storedUser) {
        try {
          const parsedUser = JSON.parse(storedUser) as UserProfile;
          setToken(storedToken);
          setUser(parsedUser);
          liveSyncService.init();
          liveSyncService.connect();
          // Trigger initial sync on application boot
          syncService.syncNow().catch((err) => console.warn('Boot sync error:', err));
        } catch (_) {
          clearAuthSession();
        }
      }
      setIsLoading(false);
    };

    initializeAuth();
  }, []);

  const loginWithGoogle = async (idToken: string) => {
    setIsLoading(true);
    try {
      const authData = await api.authenticateWithGoogle(idToken);
      setToken(authData.token);
      setUser(authData.user);
      setAuthSession(authData.token, authData.user);
      liveSyncService.init();
      liveSyncService.connect();
      await syncService.syncNow().catch((err) => console.warn('Post-login sync error:', err));
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    liveSyncService.disconnect();
    clearAuthSession();
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        isLoading,
        loginWithGoogle,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

