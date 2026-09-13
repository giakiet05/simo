import type {
  UserProfile,
  SyncRequestBody,
  SyncResponseData,
  Transaction,
  Wallet,
} from '../types';

export type { UserProfile } from '../types';

export interface AuthResponseData {
  token: string;
  user: UserProfile;
}

export interface DashboardSummary {
  total_assets: number;
  month_income: number;
  month_expense: number;
  month_balance: number;
  month_budget: number;
  budget_remaining: number;
  category_shares: Array<{
    category_id: string;
    category_name: string;
    color: string;
    total_amount: number;
    percentage: number;
  }>;
}

export const getBaseUrl = () => {
  return (
    import.meta.env.VITE_API_BASE_URL ||
    localStorage.getItem('simo_api_base_url') ||
    'http://localhost:8080/api/v1'
  );
};

export const getAuthToken = () => {
  return localStorage.getItem('simo_auth_token') || '';
};

export const setAuthSession = (token: string, user: UserProfile) => {
  localStorage.setItem('simo_auth_token', token);
  localStorage.setItem('simo_user_profile', JSON.stringify(user));
};

export const clearAuthSession = () => {
  localStorage.removeItem('simo_auth_token');
  localStorage.removeItem('simo_user_profile');
};

export async function apiFetch<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${getBaseUrl()}${endpoint}`;
  const token = getAuthToken();

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...((options.headers as Record<string, string>) || {}),
  };

  const response = await fetch(url, { ...options, headers });
  if (!response.ok) {
    let errorMsg = `API error (${response.status})`;
    try {
      const errJson = await response.json();
      if (errJson.message) errorMsg = errJson.message;
    } catch (_) {
      errorMsg = await response.text();
    }
    throw new Error(errorMsg);
  }

  const json = await response.json();
  return json.data as T;
}

export const api = {
  authenticateWithGoogle: async (idToken: string): Promise<AuthResponseData> => {
    return apiFetch<AuthResponseData>('/auth/google', {
      method: 'POST',
      body: JSON.stringify({ id_token: idToken }),
    });
  },

  getMe: async (): Promise<UserProfile> => {
    return apiFetch<UserProfile>('/auth/me');
  },

  sync: async (payload: SyncRequestBody): Promise<SyncResponseData> => {
    return apiFetch<SyncResponseData>('/sync', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  getDashboard: (year?: number, month?: number) => {
    const query = new URLSearchParams();
    if (year) query.set('year', year.toString());
    if (month) query.set('month', month.toString());
    return apiFetch<DashboardSummary>(`/dashboard?${query.toString()}`);
  },

  getTransactions: (params: { page?: number; limit?: number; type?: string; keyword?: string }) => {
    const query = new URLSearchParams();
    if (params.page) query.set('page', params.page.toString());
    if (params.limit) query.set('limit', params.limit.toString());
    if (params.type) query.set('type', params.type);
    if (params.keyword) query.set('keyword', params.keyword);
    return apiFetch<{ items: Transaction[]; total: number; page: number; limit: number }>(
      `/transactions?${query.toString()}`
    );
  },

  getWallets: () => {
    return apiFetch<Wallet[]>('/wallets');
  },
};
