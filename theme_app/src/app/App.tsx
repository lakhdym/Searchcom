import React, { useState } from 'react';
import { LanguageSelector } from './components/LanguageSelector';
import { Home } from './components/Home';
import { PostForm } from './components/PostForm';
import { Navbar } from './components/Navbar';
import { Toaster } from 'sonner';

export type Page = 'LANGUAGE' | 'HOME' | 'FORM_LOST' | 'FORM_FOUND';
export type Language = 'ar' | 'fr' | 'en';

export default function App() {
  const [currentPage, setCurrentPage] = useState<Page>('LANGUAGE');
  const [currentLang, setCurrentLang] = useState<Language>('fr');

  const handleLanguageSelect = (lang: Language) => {
    setCurrentLang(lang);
    setCurrentPage('HOME');
  };

  const navigateTo = (page: Page) => {
    setCurrentPage(page);
  };

  return (
    <div className="min-h-screen bg-gray-50 font-sans text-gray-900 selection:bg-violet-100 selection:text-violet-900">
      <Toaster position="top-center" />
      
      {currentPage !== 'LANGUAGE' && (
        <Navbar onNavigateHome={() => navigateTo('HOME')} />
      )}

      <main className={currentPage !== 'LANGUAGE' ? "container mx-auto px-4 py-6 max-w-5xl" : ""}>
        {currentPage === 'LANGUAGE' && (
          <LanguageSelector onSelect={handleLanguageSelect} />
        )}

        {currentPage === 'HOME' && (
          <Home 
            onNavigateForm={(type) => navigateTo(type === 'lost' ? 'FORM_LOST' : 'FORM_FOUND')} 
          />
        )}

        {(currentPage === 'FORM_LOST' || currentPage === 'FORM_FOUND') && (
          <PostForm 
            type={currentPage === 'FORM_LOST' ? 'lost' : 'found'}
            onCancel={() => navigateTo('HOME')}
            onSuccess={() => navigateTo('HOME')}
          />
        )}
      </main>
    </div>
  );
}
