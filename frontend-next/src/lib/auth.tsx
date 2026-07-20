"use client";

import { createContext, useContext, useEffect, useState, useCallback } from "react";
import { api } from "@/lib/api";
import type { User } from "@/types";

interface AuthState {
  user: User | null;
  token: string | null;
  loading: boolean;
  initialized: boolean;
  isAuthenticated: boolean;
  isCreator: boolean;
  isEnterprise: boolean;
  isAdmin: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (body: {
    email: string;
    password: string;
    username?: string;
    role?: string;
    phone_number?: string;
    referral_code?: string;
  }) => Promise<User>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | null>(null);
const TOKEN_KEY = "tj_token";

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [initialized, setInitialized] = useState(false);

  // Restore session on boot.
  useEffect(() => {
    const saved = typeof window !== "undefined" ? localStorage.getItem(TOKEN_KEY) : null;
    if (!saved) {
      setInitialized(true);
      return;
    }
    setToken(saved);
    api
      .me(saved)
      .then((u) => setUser(u))
      .catch(() => {
        localStorage.removeItem(TOKEN_KEY);
        setToken(null);
      })
      .finally(() => setInitialized(true));
  }, []);

  const persist = useCallback((tok: string, u: User) => {
    localStorage.setItem(TOKEN_KEY, tok);
    setToken(tok);
    setUser(u);
  }, []);

  const login = useCallback(
    async (email: string, password: string) => {
      setLoading(true);
      try {
        const res = await api.login(email, password);
        persist(res.token, res.user);
      } finally {
        setLoading(false);
      }
    },
    [persist],
  );

  const register = useCallback(
    async (body: Parameters<typeof api.register>[0]) => {
      setLoading(true);
      try {
        const res = await api.register(body);
        persist(res.token, res.user);
        return res.user;
      } finally {
        setLoading(false);
      }
    },
    [persist],
  );

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    setToken(null);
    setUser(null);
  }, []);

  const value: AuthState = {
    user,
    token,
    loading,
    initialized,
    isAuthenticated: !!token && !!user,
    isCreator: user?.role === "creator",
    isEnterprise: user?.role === "enterprise",
    isAdmin: user?.role === "admin",
    login,
    register,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
