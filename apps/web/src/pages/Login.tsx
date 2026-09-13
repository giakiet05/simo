import React, { useState } from 'react';
import { GoogleLogin } from '@react-oauth/google';
import { useAuth } from '../contexts/AuthContext';
import { ShieldCheck, Sparkles, Wallet, AlertCircle } from 'lucide-react';

export const Login: React.FC = () => {
  const { loginWithGoogle, isLoading } = useAuth();
  const [error, setError] = useState<string | null>(null);

  const handleGoogleSuccess = async (credentialResponse: any) => {
    setError(null);
    if (!credentialResponse.credential) {
      setError('Google Sign-In did not return valid credentials.');
      return;
    }
    try {
      await loginWithGoogle(credentialResponse.credential);
    } catch (err: any) {
      setError(err.message || 'Đăng nhập thất bại. Vui lòng thử lại.');
    }
  };

  const handleGoogleError = () => {
    setError('Quá trình đăng nhập Google bị gián đoạn hoặc thất bại.');
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-center items-center px-4">
      {/* Background glowing gradients */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 left-1/3 w-72 h-72 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="relative w-full max-w-md bg-slate-900/80 border border-slate-800 backdrop-blur-xl rounded-2xl p-8 shadow-2xl">
        {/* App Logo & Header */}
        <div className="flex flex-col items-center text-center mb-8">
          <div className="w-14 h-14 bg-gradient-to-tr from-teal-500 to-emerald-400 rounded-2xl flex items-center justify-center shadow-lg shadow-teal-500/20 mb-4">
            <Wallet className="w-8 h-8 text-slate-950 font-bold" />
          </div>
          <h1 className="text-2xl font-extrabold tracking-tight bg-gradient-to-r from-teal-300 via-emerald-300 to-white bg-clip-text text-transparent">
            Simo Finance
          </h1>
          <p className="text-sm text-slate-400 mt-1">
            Quản lý tài chính cá nhân & đồng bộ đa nền tảng
          </p>
        </div>

        {error && (
          <div className="mb-6 p-3 bg-red-950/50 border border-red-800/60 rounded-xl flex items-start gap-2.5 text-red-300 text-xs">
            <AlertCircle className="w-4 h-4 text-red-400 shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        {/* Auth Buttons */}
        <div className="flex flex-col items-center justify-center gap-4">
          <div className="w-full flex justify-center">
            {isLoading ? (
              <div className="py-3 flex items-center gap-2 text-sm text-teal-400">
                <div className="w-4 h-4 border-2 border-teal-400 border-t-transparent rounded-full animate-spin" />
                <span>Đang xử lý đăng nhập...</span>
              </div>
            ) : (
              <div className="w-full flex justify-center">
                <GoogleLogin
                  onSuccess={handleGoogleSuccess}
                  onError={handleGoogleError}
                  theme="filled_black"
                  shape="pill"
                  size="large"
                  text="signin_with"
                />
              </div>
            )}
          </div>
        </div>

        {/* Feature Highlights */}
        <div className="mt-8 pt-6 border-t border-slate-800/60 flex items-center justify-around text-xs text-slate-400">
          <div className="flex items-center gap-1.5">
            <ShieldCheck className="w-4 h-4 text-teal-400" />
            <span>Bảo mật dữ liệu</span>
          </div>
          <div className="flex items-center gap-1.5">
            <Sparkles className="w-4 h-4 text-emerald-400" />
            <span>Đồng bộ tức thì</span>
          </div>
        </div>
      </div>

      <footer className="mt-8 text-xs text-slate-400">
        Simo Monorepo &copy; {new Date().getFullYear()}
      </footer>
    </div>
  );
};
