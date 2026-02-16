import React from 'react';
import { Language } from '../App';
import { motion } from 'motion/react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface LanguageSelectorProps {
  onSelect: (lang: Language) => void;
}

export const LanguageSelector: React.FC<LanguageSelectorProps> = ({ onSelect }) => {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-white p-6">
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md text-center space-y-8"
      >
        <div className="space-y-2">
          <h1 className="text-3xl font-bold text-gray-900">
            Bienvenue / Welcome / مرحبا
          </h1>
          <p className="text-gray-500 text-lg">
            Choisissez votre langue / Choose your language
          </p>
        </div>

        <div className="grid gap-4">
          <LanguageButton 
            lang="ar" 
            label="Arabe" 
            imgSrc="https://images.unsplash.com/photo-1600854858180-cca8bab5c57e?auto=format&fit=crop&w=100&h=100"
            onClick={() => onSelect('ar')}
          />
          <LanguageButton 
            lang="fr" 
            label="Français" 
            imgSrc="https://images.unsplash.com/photo-1551866442-64e75e911c23?auto=format&fit=crop&w=100&h=100"
            onClick={() => onSelect('fr')}
          />
          <LanguageButton 
            lang="en" 
            label="English" 
            imgSrc="https://images.unsplash.com/photo-1623577287452-68b18b24a4d8?auto=format&fit=crop&w=100&h=100"
            onClick={() => onSelect('en')}
          />
        </div>
      </motion.div>
    </div>
  );
};

interface LanguageButtonProps {
  lang: string;
  label: string;
  imgSrc: string;
  onClick: () => void;
}

const LanguageButton: React.FC<LanguageButtonProps> = ({ lang, label, imgSrc, onClick }) => {
  return (
    <motion.button
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className="flex items-center p-4 bg-gray-50 hover:bg-violet-50 border border-gray-100 hover:border-violet-200 rounded-2xl transition-colors shadow-sm w-full group"
    >
      <div className="relative w-12 h-12 rounded-full overflow-hidden border border-gray-200 group-hover:border-violet-300 shadow-sm shrink-0">
        <ImageWithFallback 
          src={imgSrc} 
          alt={label}
          className="w-full h-full object-cover"
        />
      </div>
      <span className="flex-1 text-left rtl:text-right px-6 font-semibold text-lg text-gray-700 group-hover:text-violet-700">
        {label}
      </span>
      <span className="text-gray-300 group-hover:text-violet-400">
        →
      </span>
    </motion.button>
  );
};
