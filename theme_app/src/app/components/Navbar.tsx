import React from 'react';
import { Bell, MessageSquare, LogIn, Search, MapPin } from 'lucide-react';
import { motion } from 'motion/react';

interface NavbarProps {
  onNavigateHome: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onNavigateHome }) => {
  return (
    <header className="sticky top-0 z-50 bg-white border-b border-gray-100 shadow-sm backdrop-blur-md bg-opacity-80">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        {/* Logo */}
        <button 
          onClick={onNavigateHome}
          className="flex items-center gap-2 group"
        >
          <div className="w-8 h-8 bg-violet-600 rounded-lg flex items-center justify-center text-white font-bold text-lg shadow-violet-200 shadow-lg group-hover:scale-105 transition-transform">
            T
          </div>
          <span className="font-bold text-xl tracking-tight text-gray-900">
            Trouvé<span className="text-violet-600">!</span>
          </span>
        </button>

        {/* Actions */}
        <div className="flex items-center gap-2 md:gap-4">
          <button className="relative p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors">
            <Bell size={20} />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border border-white"></span>
          </button>
          
          <button className="p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors hidden sm:block">
            <MessageSquare size={20} />
          </button>

          <div className="h-6 w-px bg-gray-200 mx-1 hidden sm:block"></div>

          <button className="flex items-center gap-2 px-4 py-2 bg-gray-900 hover:bg-gray-800 text-white rounded-full text-sm font-medium transition-colors shadow-md">
            <LogIn size={16} />
            <span className="hidden sm:inline">Se connecter</span>
          </button>
        </div>
      </div>
    </header>
  );
};
